import psycopg2
import atexit
import datetime
import json
import secrets
from _helperfunc import *
import gc
import warnings
from psycopg2.extras import DictCursor

SYSTEM_TAGS_PREFIX = "postgresql_"


conn_kwargs = dict(
	#detect_types=sqlite3.PARSE_DECLTYPES,
	#check_same_thread=False
)
conn = psycopg2.connect(
    host="localhost",
    user="postgres",
    password="postgres",
    **conn_kwargs
    )


#Supports '?' as placeholder. ie, query: execute('SELECT ? FROM ?',("name","table"))
# goddamn garbage cursor executor, best format the string youself
if __name__ != "__main__":
	def execute(*vargs,**kwargs):	return db_exec(*vargs,**kwargs) # Wrapper
def db_execute(*vargs,**kwargs):	return db_exec(*vargs,**kwargs) # Wrapper
def db_exec(_sqlExec_, execType=None, withCommit=False, *vargs, cursor2use=None, **kwargs):
	ph = None
	if isinstance(_sqlExec_, (list, tuple)):	_sqlExec_, *ph = _sqlExec_
	if execType is None:
		match(tuple( regex.findall(r'[^\S\n\r]*([a-zA-Z]+)(?=\s|$)', _sqlExec_.upper()) )):
			case (
				('SELECT', *_) | ('CREATE', *_) | ('DELETE', 'FROM', *_) |
				('DROP', *_) | ("PRAGMA", *_) | ('UPDATE', *_)
			): execType = 'one'
			case ('INSERT', 'INTO', *_):
				execType = 'many' if ph and len(getDimensions(ph)) > 1 else 'one'
	
	# Clauses breakdown and string ignore algo goes here to sub ? to %s
	
	result = None
	if cursor2use is None: cursor2use = conn.cursor()
	
	match(execType):
		case 'one':  result = cursor2use.execute(_sqlExec_, ph)
		case 'many': result = cursor2use.executemany(_sqlExec_, ph)
	if withCommit: conn.commit()
	return cursor2use


class DB_account(metaclass=__noinit_meta__):
	findable_by = ["User ID","Name","email","mobile number"] # UserId is the only unique one
	def __new__(cls,*vargs,**kwargs):
		if len(vargs) > 0 and type(vargs[0]) == cls:	return vargs[0]
		obj = super().__new__(cls)
		obj.__init__(*vargs, **kwargs)
		return obj
	def __init__(self, *, findby=None, **kwargs):
		if findby is None:	findby = dict(list(kwargs.items())[0])
		try:
			acc = db_exec(
					#("SELECT * FROM userprofile WHERE %s = %s", *{**findby}.popitem()),
					(f"SELECT * FROM userprofile WHERE \"{(*findby.keys(),)[0]}\" = %s", *findby.values()),
					cursor2use=conn.cursor(cursor_factory=DictCursor)
				  ).fetchall()
		except Exception as er:
			conn.rollback()
			raise ValueError(
				re_Template.on("Invalidated retrevial of account from database. Reason:\n  {{%er%}}",
								custom_sub = {"er":re_Template.pythonicLoader(er2string(er))}
								)) from None
		match(len(acc)):
			case 0: raise ValueError("No Account was found")
			case 1: pass
			case _: warnings.warn("Account has more than one results.")
		acc = acc[0]
		self.__account = acc
		__userfeatures = db_exec(
				("SELECT * FROM userfeatures WHERE uid = %s", (self.__account["User ID"],)),
				cursor2use=conn.cursor(cursor_factory=DictCursor)
				).fetchone()
		if __userfeatures is None:
			warnings.warn("Selected user has no entry in userfeatures")
		else:
			self.__userfeatures = __userfeatures
			uid_index = list(self.__userfeatures.keys())
			if "uid" in uid_index:	self.__userfeatures.pop(uid_index.index("uid"))
	def __getitem__(self, _item):
		if type(_item) == str:
			if regex.match(r"^features$",_item):
				if hasattr(self, f"_{__class__.__name__}__userfeatures"):	return self.__userfeatures
				elif _item in self.__account:	return self.__account[_item]
				else:	raise AttributeError(f"The account does not have any features or account key named '{_item}'")
			if _item in self.__account:	return self.__account[_item]
			else:			raise AttributeError(f"The account does not have any account key named '{_item}'")
		elif isinstance(_item, (tuple, list)):
			match(_item):
			  case ("account", x) | ("acc", x) | (0, x):
			  	if x in self.__account:	return self.__account[x]
			  	else:			raise AttributeError(f"The account does not have any account key named '{x}'")
			  case ("features", x) | (1, x):
			  	if x in self.__userfeatures:	return self.__userfeatures[x]
			  	else:			raise AttributeError(f"The account does not have any feature named '{x}'")
			  case ("account", ) | ("acc", ) | (0, ):
			  	return self.__account
			  case ("features", ) | (1, ):
			  	if hasattr(self, f"_{__class__.__name__}__userfeatures"): return self.__userfeatures
			  	raise AttributeError(f"The account does not have features.")
			  case x:
			  	raise SyntaxError(f"{x} is not an allowed operation. Use ('', KEY) for retreiving  keys or ('', KEY) for retreiving   keys")
		elif type(_item) == int:
			match(_item):
			  case 0: return self.__account
			  case 1:
			  	if hasattr(self, f"_{__class__.__name__}__userfeatures"):	return self.__userfeatures
			  	else:				raise AttributeError("The account does not have any features.")
			  case _: raise AttributeError(f"Account does not support {_item} index.")
		else:
			raise SyntaxError(f"{_item} is not an allowed operation.")
	def __setitem__(self, _item, _val):
		if type(_item) == str:
			if _item == "metadata":	self.meta = _val
			else:			self.file[_item] = _val
		elif isinstance(_item, (tuple, list)):
			match(_item):
			  case ("account", x) | ("acc", x) | (0, x):		self.__account[x] = _val
			  case ("features", x) | (1, x):	self.__userfeatures[x] = _val
			  case ("account", ) | ("acc", ) | (0, ):		self.__account = _val
			  case ("features", ) | (1, ):		self.__userfeatures = _val
			  case x:
			  	raise SyntaxError(f"{x} is not an allowed operation. Use ('', KEY) for setting  keys or ('metadata', KEY) for setting  keys")
		elif type(_item) == int:
			match(_item):
			  case 0: self.__account = _val
			  case 1: self.__userfeatures = _val
			  case _: raise AttributeError(f"Account does not support {_item} index. Only use 0 () and 1 ().")
		else:
			raise SyntaxError(f"{_item} is not an allowed operation.")
	def keys(self, which=0, convert=False):
		match(which):
			case 0 | "acc" | "account": return tuple(self.__account.keys()) if convert else self.__account.keys()
			case 1 | "features": return tuple(self.__userfeatures.keys()) if convert else self.__userfeatures.keys()
			case _: raise AttributeError(f"Account does not support {which} index.")
	def __iter__(self):	return iter(self.keys())
	def __contains__(self, query):
		if type(query) == str: return query in self.keys()
	def __repr__(self):
		repr_newline = "\n" if getattr(__class__, "repr_newline", False) else " "
		def acc_prof_repr(k,v):
			try: v = json.dumps(v,**{k:v for k,v in [["indent",2]] if getattr(__class__, "repr_newline", False)})
			except: v = repr(v)
			return f"{k} = {regex.sub(r"(?<=^[\s\S]{25})[\s\S]+$","...",v)}"
		account = f",{repr_newline}".join(acc_prof_repr(k,v) for k,v in self.__account.items()) if hasattr(self, f"_{__class__.__name__}__account") else None
		features = f",{repr_newline}".join(acc_prof_repr(k,v) for k,v in self.__userfeatures.items()) if hasattr(self, f"_{__class__.__name__}__userfeatures") else None
		account, features = f"{repr_newline}{account}{repr_newline}", f"{repr_newline}{features}{repr_newline}"
		return f"<DB_Document{",".join([(f" user[{account}]" if account else ""), (f" features[{features}]" if features else "")])}>"
	def has_features(self):
		return hasattr(self, "_{__class__.__name__}__userfeatures")
	def copy(self): return copy.deepcopy(self)
	def savesettings(self, commit=False):
		_consts = ["User ID"]
		change_settings = dict(self.__account).copy()
		for x in _consts: change_settings.pop(x, None)
		sqlCMD = f"UPDATE userprofile\nSET {
				",\n".join(f"\"{key}\" = %s" for key in change_settings.keys())
			}\nWHERE \"User ID\" = %s"
		sqlParse = (sqlCMD, *change_settings.values(), self.__account["User ID"])
		db_exec(sqlParse,withCommit=commit)
		try: # for now
			change_settings = self.__userfeatures.copy()
			for x in _consts: change_settings.pop(x, None)
			sqlCMD = f"UPDATE userfeatures SET {
					", ".join(f"\"{key}\" = %s" for key in change_settings.keys())
					} WHERE \"uid\" = %s"
			sqlParse = (sqlCMD, *change_settings.values(), self.__account["User ID"])
			db_exec(sqlParse,withCommit=commit)
		except:
			pass
	@staticmethod
	def register(credentials, features=None):
		required_keys = {"email","password","Name"}
		if credentials.keys() < required_keys:
			raise ValueError(f"Invalid account creation. Missing: { ", ".join(required_keys.difference(credentials.keys())) }")

		generate_userid = db_exec("SELECT \"User ID\" FROM userprofile").fetchall() # why is johnny so high up?
		for x in range(240):
			x = secrets.token_hex(25) #25 here means 25nbytes which is 50 characters
			if x not in generate_userid: break
		else: # if completed loop, aka didnt work
			raise IndexError("Unable to find a uid for registration")
		credentials["User ID"] = x
		try:
			acc = db_exec(
				(f"INSERT INTO userprofile({
					",".join(f'"{k}"' for k in credentials.keys())
				 }) VALUES ({
				 ",".join("%s" for x in credentials)
				 })", *credentials.values()), withCommit=True
			)
		except Exception as er:
			conn.rollback()
			if type(er) == psycopg2.errors.UniqueViolation: raise er
			raise psycopg2.DatabaseError(
				re_Template.on("Invalid creation of account from database. Reason:\n  {{%er%}}",
								custom_sub = {"er":re_Template.pythonicLoader(er2string(er))}
								)) from None
		if features:
			db_exec(
					(f"INSERT INTO userfeatures({
						",".join(f'"{k}"' for k in features.keys())
					 }) VALUES ({
					 ",".join("%s" for x in features)
					 })", *features.values()), withCommit=True
				)
		acc = DB_account(findby={"email":credentials["email"]})
		return acc
	@staticmethod # unused for now.
	def collate(obj):
		acc_columns = DBm.db_exec("SELECT * FROM userprofile LIMIT 0").description
		feat_columns = DBm.db_exec("SELECT * FROM userfeatures LIMIT 0").description
		if type(obj) == dict:
			if "features" in obj:
				features = obj.pop("features")
			for x in p: pass
		elif type(obj) == __class__: pass


def DATABASE_FORCE_REINSTANTIATE_MAIN_DATABASE():
	db_exec("DROP TABLE documents", 'one', True)
	db_exec("DROP TABLE tags_list", 'one', True)
	db_exec("CREATE TABLE documents(title TEXT,desc TEXT,datetime DATETIME,timeregistered DATETIME,url_link TEXT NOT NULL,metadata JSONWRAPPER,author TEXT,tags ARRAY,content TEXT,summary TEXT,PRIMARY KEY (url_link));")
	db_exec("CREATE TABLE tags_list(tagId INTEGER PRIMARY KEY AUTOINCREMENT,tagName TEXT UNIQUE);")
	db_insert([[f'{SYSTEM_TAGS_PREFIX}{x}'] for x in ["BASE_TAG","Hidden","Masked"]], tablename="tags_list(tagName)")

def on_exit():
	print("Shutting down the database. Doing some clean-ups")
	for obj in gc.get_objects():
		try:
			if isinstance(obj, psycopg2.extensions.connection) and obj.closed == 1:
				print(f'Attempting to close an unclosed connection: {obj}.')
				try:
					obj.close()
					if not obj.closed: raise Exception()
				except:
					obj.interrupt()
					obj.close()
					if not obj.closed: raise Exception()
		except Exception as er:
			PrintC.red(f'ERROR: Cannot close {_varval}, (_var)')
	print("Database has shutdown.")
	return
atexit.register(on_exit)