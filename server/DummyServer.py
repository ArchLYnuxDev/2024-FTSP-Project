from flask import Flask, request, jsonify, stream_with_context, Response, session
from flask_session import Session as flaskSession
import os, sys
import json
import secrets
import configparser
import io
import logging
import threading
import atexit
import time
import regex
import database_manager as DBm
import hashlib
import datetime
from _helperfunc import *


os.chdir(os.path.dirname(__file__))
print(os.getcwd())
json_dir = "."

class Server:
    __target = "flask"
    __server_config_path = "server_config.cfg"
    def __init__(self, _flaskApp=None, _flaskSocket=None):
        self._Flask = _flaskApp or Flask("Dummy Server For Flutter", static_url_path="", static_folder="")
        self._Flask.config["SESSION_TYPE"] = "filesystem"
        self.session = flaskSession(self._Flask)
        #self._Socket = None or SocketIO(self._Flask)
        
    def go_online(self, host="0.0.0.0", port=None, *, debug=False, useConfig=True, mainThread=True, **kwargs):
        kwargs = dict(
                use_reloader = False,
                use_evalex = False,
                **kwargs
            )
        if useConfig:
            svr_config = configparser.ConfigParser()
            changesMade = {}
            if os.path.exists(self.__server_config_path): svr_config.read(self.__server_config_path)
            
            if "Network" not in svr_config:
                svr_config["Network"] = {}
                changesMade = {"/Network": "Add"}
            secret_key = svr_config["Network"].get("secret_key")
            if secret_key is None:
                secret_key = svr_config["Network"]["secret_key"] = secrets.token_hex()
                changesMade = {"/Network/secret_key": "Add"}
                
            
            if changesMade:
                with open(self.__server_config_path, "w") as f:
                    svr_config.write(f)
                    
            ssl_cert = svr_config["Network"].get("ssl_certificate")
            if ssl_cert is not None and "ssl_context" not in kwargs:
                if (ssl_cert:=regex.search(r"((^.+\s*,\s+.+$)|(^adhoc$))|()",ssl_cert).group(1)):
                    if(ssl_cert != "adhoc"): ssl_cert = (ssl_cert, svr_config["Network"].get("ssl_key"))
                    kwargs["ssl_context"] = ssl_cert
                    print("running with SSL")
            self._Flask.secret_key = secret_key
            
        if mainThread:
            if getattr(self, "_Socket", False): return self._Socket.run(self._Flask, host, port, debug=debug, **kwargs)
            return self._Flask.run(host, port, debug=debug, **kwargs)
            
        self._logger = logging.getLogger("werkzeug")
        for handler in self._logger.handlers: self._logger.removeHandler(handler)
        class StringIOWrapper(io.StringIO):
            _wrapper_Hooks = {}
            __stored_new = ""
            def write(self,s):
                self.__stored_new += s
                for hook in self._wrapper_Hooks.values(): hook(s)
                return super().write(s)
            def read_new(self, size=-1):
                readed, self.__stored_new = self.__stored_new, ""
                return readed
            def peek_new(self):
                return self.__stored_new
        self.__stream = StringIOWrapper()
        self.__handler = logging.StreamHandler(self.__stream)
        self._logger.addHandler(self.__handler)
        def _thread_target():
            if getattr(self, "_Socket", False): return self._Socket.run(self._Flask, host, port, debug=debug, **kwargs)
            return self._Flask.run(host, port, debug=debug, **kwargs)
        thread = threading.Thread(target=_thread_target)
        thread.daemon = True
        thread.start()
        #adds a kill server if running on non-main thread
        def shutdown(self):
            try:
                func = request.environ.get("werkzeug.server.shutdown")
                if func is None: return print("Unable to shutdown server")
            except Exception as er: print("Server has shutdown")
        self.shutdown_server = shutdown.__get__(self)
        atexit.register(self.shutdown_server)
        trackTime = [0, time.perf_counter()]
        def resetTrackTime(x):
            nonlocal trackTime
            sys.stdout.write(x)
            self.__stream._StringIOWrapper__stored_new = ""
            trackTime[0] += 1
        self.add_console_stream_hook(resetTrackTime, "onstartup_hook")
        while trackTime[0] < 2 and time.perf_counter() - trackTime[1] < 1.5: pass
        self.remove_console_stream_hook("onstartup_hook")
        return thread
        
    def add_console_stream_hook(self, hookFunc, name=None):
        if name is None: name = hookFunc.__qualname__
        old_name = name
        while name in self.__stream._wrapper_Hooks:
            name_list = list(filter(lambda x: regex.match(rf"^{old_name}_\d+$", x), self.__stream._wrapper_Hooks.keys()))
            name_list.sort(key=lambda x: int(regex.search(rf"(?<={old_name}_)\d+", x).group()))
            name = f"{old_name}{int(regex.search(rf"(?<={old_name}_)\d+", name_list[-1]).group())+1}"
        self.__stream._wrapper_Hooks[name] = hookFunc
        return name

    def remove_console_stream_hook(self, name):
        old_name = name
        if name not in self.__stream._wrapper_Hooks:
            name_list = list(filter(lambda x: regex.match(rf"^{old_name}_\d+$", x), self.__stream._wrapper_Hooks.keys()))
            if not name_list: raise ValueError()
            name_list.sort(key=lambda x: int(regex.search(rf"(?<={old_name}_)\d+", x).group()))
            name = f"{old_name}{int(regex.search(rf"(?<={old_name}_)\d+", name_list[-1]).group())+1}"
        del self.__stream._wrapper_Hooks[name]

    def get_console_stream_hooks(self):         return self.__stream._wrapper_Hooks
    def get_stream(self): return self.__stream
    def log(self, x=""): return self._logger.info(x)

    def go_debug(self) -> None:
        self._Socket.run(self._Flask)

    def __getattr__(self, attrName): #assumes fail
        match self.__target:
            case 'flask': return getattr(self._Flask, attrName)
            case 'socket': return getattr(self._Socket, attrName)
        raise ValueError("The targeted component is invalid.")

    def setTarget(self, target='toggle'):
        if target == 'toggle': target = "socket" if self.__target == "flask" else "flask"
        self.__target = target

# Function to get JSON response based on mode
def get_json_response(json_data):
    vehiclemode = json_data['vehiclemode']
    mode = json_data['mode']
    topn = json_data['topn']   
    file_path = f"vehiclemode_{vehiclemode}_mode_{mode}_topn_{topn}.json"
    using_dir = os.path.abspath(os.path.join(os.getcwd(), json_dir))
    
    try:
        with open(os.path.join(using_dir, file_path), 'r') as file:
            json_response = json.load(file)
        return json_response
    except FileNotFoundError:
        return {'error': f'File for mode {mode} not found'}
    except Exception as e:
        return {'error': f'An error occurred: {str(e)}'}

# Generator function to stream JSON response
def generate_json_response(json_data):
    response = get_json_response(json_data)
    yield json.dumps(response)

app = Server()

# Everything below here, i only very roughly coded. Pardon the poor coding.

@app.route("/login", methods=["POST"])
def validate_login():
	try:
		header, body = request.headers, request.json
		required_keys = {"email","password"}
		if body.keys() < required_keys:
			return app.response_class(
				response = json.dumps({"error": f"Invalid access. Missing components: { ", ".join(required_keys.difference(body.keys())) }"}),
				status = 201
			)
			
		try:
			account = DBm.DB_account(findby={"email":body["email"]})
		except:
			return app.response_class(
				response = json.dumps({"error": f"Invalid access. Account not found."}),
				status = 201
			)
		if account["password"] != body["password"]:
			return app.response_class(
				response = json.dumps({"error": f"Invalid access. Incorrect password."}),
				status = 201
			)

		if "email" in session:
			print(f"{body["email"]} is already logged in but is logging again!")
			return app.response_class(
				response = json.dumps({"error": "Already Logged in!"}),
				status = 210
			)
		session["email"] = body["email"]
		print(f"{body["email"]} has logged in.")
		return app.response_class(
			response = json.dumps({"text":"Sucessfully logged in."}),
			status = 200
		)
	except Exception as er:
		return app.response_class(
			response = json.dumps({"error":f"SERVER ERROR. {er}"}),
			status = 244
		)

@app.route("/logout", methods=["GET"]) 
def logout():
	try:
		header, body = request.headers, None#request.body
		if "email" in session and session.get("email") is not None:
			print(f"{session.get("email")} has logged out!")
			session.pop("email")
			return app.response_class(
				response = json.dumps({"text": "Successfully logged out!"}),
				status = 200
			)
		return app.response_class(
			response = json.dumps({"error": f"Invalid access. You are not logged in!"}),
			status = 210
		)
	except Exception as er:
		return app.response_class(
			response = json.dumps({"error":f"SERVER ERROR. {er}"}),
			status = 244
		)
	
@app.route("/register", methods=["POST"]) 
def register():
	try:
		header, body = request.headers, request.json
		try:
			acc = DBm.DB_account.register(request.json)
		except ValueError as er:
			return app.response_class(
				response = json.dumps({"error": f"Invalid access. {er2string(er)}."}),
				status = 201
			)
		except IndexError as er:
			return app.response_class(
				response = json.dumps({"error": f"An uid was not completable."}),
				status = 220
			)
		except Exception as er:
			print(er2string(er))
			return app.response_class(
				response = json.dumps({"error": f"An error has occured."}),
				status = 220
			)

		print(f"{body["email"]} has registered. UID: {acc["User ID"]}")
		return app.response_class(
			response = json.dumps({"text":"Sucessfully registered!", "User ID": f"{acc["User ID"]}"}),
			status = 200
		)
	except Exception as er:
		print(f"\033[91m{er2string(er)}\033[0m")
		return app.response_class(
			response = json.dumps({"error":f"SERVER ERROR. {er}"}),
			status = 244
		)
	
@app.route("/accountdetails", methods=["GET","PUT"]) 
def account_details():
	try:
		header, body = request.headers, request.data
		excludeColumns = ["password"]
		if "email" not in session:
			return app.response_class(
				response = json.dumps({"error": f"Invalid access. Cannot retrieve account details as user is not logged in."}),
				status = 210
			)

		try:
			acc = DBm.DB_account(findby={"email":session["email"]})
		except Exception as er:
			return app.response_class(
				response = json.dumps({"error": f"An error has occured. {er2string(er)}"}),
				status = 220
			)
			
		details = {
			"account":		{k:v for k,v in acc["account",].items() if k not in excludeColumns},
			"features":		{k:v for k,v in acc["features",].items() if k not in excludeColumns} if acc.has_features() else None
		}
		acc_columns = DBm.db_exec("SELECT * FROM userprofile LIMIT 0").description
		feat_columns = DBm.db_exec("SELECT * FROM userfeatures LIMIT 0").description
		
		def _jsonify(x):
			match(x):
				case 1082: return str
				case _: return lambda x: x
			
		match (request.method):
			case "PUT":
				body = json.loads(body.decode("UTF-8"))
				if body:
					acc_data = body.get("account",{})
					feat_data = body.get("features",{})
					if acc_data.keys() <= {x.name for x in acc_columns} and feat_data.keys() <= {x.name for x in feat_columns}:
						for k,v in acc_data.items(): acc["account", k] = v
						if feat_data is not None:
							acc["features",] = {}
							for k,v in feat_data.items(): acc["features", k] = v
						
						acc.savesettings(True)
						return app.response_class(
							response = json.dumps({"text": f"Account has been successfully updated"}),
							status = 200
						)
					else:
						return app.response_class(
							response = json.dumps({"error": f"Invalid keys!"}),
							status = 210
						)
				else:
					return app.response_class(
						response = json.dumps({"error": f"No changes are supplied!"}),
						status = 210
					)
			case "GET":
				for x in acc_columns:
					if x.name in details["account"]: details["account"][x.name] = _jsonify(x.type_code)(details["account"][x.name])

				if details["features"] is not None:
					for x in feat_columns:
						if x.name in details["features"]: details["features"][x.name] = _jsonify(x.type_code)(details["features"][x.name])

				return app.response_class(
					response = json.dumps(details),
					status = 200,
					mimetype = 'application/json'
				)
	except Excpetion as er:
		return app.response_class(
			response = json.dumps({"error":f"SERVER ERROR. {er}"}),
			status = 244
		)

# Added for compatiability sake
# Do things here.
@app.route("/forgetpassword", methods=["POST"]) 
def forgotpwd():
	try:
		header, body = request.headers, request.json
		try:
			acc = DBm.DB_account(findby={"email":body["email"]})
		except Exception as er:
			print(er2string(er))
			return app.response_class(
				response = json.dumps({"error": f"An error has occured."}),
				status = 220
			)
		print(f"{email} forgot their pwd :skull:")
		return app.response_class(
			response = json.dumps({"text":"Sucessful!", "User ID": f"{acc["User ID"]}"}),
			status = 200
		)
	except Exception as er:
		print(f"\033[91m{er2string(er)}\033[0m")
		return app.response_class(
			response = json.dumps({"error":f"SERVER ERROR. {er}"}),
			status = 244
		)

# Flask endpoint to process JSON data
@app.route('/getrecommendation', methods=['GET','POST']) # why tf was it POST before? shud be get only
def process_json_data():
	try:
		json_data_to_post = request.json
		return app.response_class(
			response = next(generate_json_response(json_data_to_post)), # added next as its a generator -.-
			status = 200,
			mimetype = 'application/json'
		)
	except Exception as er:
		print(f"\033[91m{er2string(er)}\033[0m")
		return app.response_class(
			response = json.dumps({"error":f"SERVER ERROR. {er}"}),
			status = 244
		)


if __name__ == '__main__':
    app.go_online(host="127.0.0.1", port=7687, mainThread=False)
    app.add_console_stream_hook(lambda x: print(x))
