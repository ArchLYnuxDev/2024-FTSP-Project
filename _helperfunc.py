import traceback
import msvcrt
import textwrap
from concurrent.futures import ThreadPoolExecutor

def post():
	global __all__
	__all__ = list(filter(lambda x: x not in __all__ and x[:2] + x[-2:] != "____", globals()))
	__all__.extend(["__noinit_meta__"])
__all__ = dir()

import regex
import sys, os
import random
import inspect
import time
import collections
import io
import threading
import subprocess
import math
import copy
from enum import Enum as enum

__noinit_meta__ = type("",(type,),{"__call__": lambda cls, *vargs, **kwargs: cls.__new__(cls,*vargs,**kwargs)})
class icls_inherit_meta(type):
	def __new__(cls, *vargs, **kwargs):
		ccls = super().__new__(cls, *vargs, **kwargs)
		attrs = super(cls, ccls).__dict__
		for aname,aval in attrs.items():
			if inspect.isclass(aval):
				print(f"{aname} is a inner class")
				print(super(type, aval).__getattribute__("__bases__")[0], ccls)
				if super(type, aval).__getattribute__("__bases__")[0] == ccls:
					print("and is also inherting")
		return ccls

def er2string(er):
	er = "".join(traceback.format_exception(None, er, er.__traceback__))
	er = er.replace("\n", "\n ")[:-2]
	return er
	
class re_Template(enum):
	def on(_Template, unnamed_sub=iter(()), named_sub={}, custom_sub={}, *, ph_token="PLACEHOLDER"):
		if not isinstance(unnamed_sub, collections.abc.Iterator): unnamed_sub = iter(unnamed_sub)
	
		regexTFitter = [
			r"({{[^\S\r\n]*)((?:" + ph_token + r"(?:_(?![-0-9])[a-zA-Z0-9_-]+)?))([^\S\r\n]*}})",
			r"({{%[^\S\r\n]*)((?:(?![-0-9])(?:[a-zA-Z0-9_-])+))([^\S\r\n]*%}})",
		]
		regexTFitter = [ regex.compile(__expr) for __expr in regexTFitter ]

		def innerregexworker(_reMatch):
			_reQuery = _reMatch.group(2)
			if _reQuery == ph_token:
				return next(unnamed_sub)
			elif _reQuery.startswith(ph_token+"_"):
				return named_sub[_reQuery.partition(ph_token+"_")[2]]
			elif _reQuery in custom_sub:
				target = custom_sub[_reQuery]
				if callable(target):
					target = target(*( [_reMatch] * (len(inspect.signature(target).parameters) > 0) ))
				return target
			else:
				PrintC("WARNING: No suitable placeholder found for template.")
				return ">!>NO_PLACEHOLDER_FOUND<!<"
		for __expr in regexTFitter: _Template = __expr.sub(innerregexworker, _Template)
		return _Template

	def pythonicLoader(_sub, verbose=0, check_comment=True):
		def customReplace(x):
			ogString = x.string
			span = x.span()
			linespan = regex.search(r"(?<=\n|^)[\p{H}\S]*?$", ogString[:span[0]])
			linespan = linespan.span()[0]
			lineno = len(regex.sub("[^\n]", "", ogString[:linespan])) + 1
			indents = regex.search(rf"^[\p{{H}}]*{"#?" * check_comment}", ogString[linespan:span[0]])
			indents = indents.group()
			if verbose: print(f"Line: {lineno}, Indents: {len(indents)}")
			return regex.sub(r"(?<=\n)()(?=.)", indents, _sub)
		return customReplace

# JSON-like class
class Table(dict):
    __slots__ = ("__dict__")
    def __new__(cls, *vargs, **kwargs):
        obj = super().__new__(cls)
        #attrTable__dict__ = type("AttributeTable", (cls,), {"__new__": lambda c,*v,**k: super(cls,c).__new__(c)})() // Not recommended.
        super(cls, obj).__setattr__("__dict__", cls.attrTable__dict__())
        return obj
    def __getattr__(self, prop):         return self.__getitem__(prop)
    def __setattr__(self, prop, val):    return self.__setitem__(prop, val)
    def __delattr__(self, prop):         return self.__delitem__(prop)
    @property
    def attr(self): return super().__getattribute__("__dict__")

Table.attrTable__dict__ = type("Table.AttributeTable", (Table,), {
    "__new__":  lambda c,*v,**k:    super(c.__bases__[0],c).__new__(c),
    "__repr__": lambda s:           f"{{ <Attribute Table> {super(s.__class__, s).__repr__()[1:]}"
})

# Ordered Table

# Note the following function is not that efficient as the iterable grows larger.
def getDimensions(_iterable, *, enforceStrict=False, cacheAxes=True):
	if not isinstance(_iterable, collections.abc.Iterable) or type(_iterable) == str:
		raise ValueError("Only non-string iterable are allowed as input!", _iterable)
	_iterable = copy.deepcopy(_iterable)

	def dimensionStepper(_iter):
		yield [len(_iter)]
		child_axes = _iter
		history_child_axes = [_iter]
		new_child_axes= []
		axes_count = 0
		while True:
			axes_count += 1
			if False in map(lambda x:hasattr(x,"__len__") and type(x) != str,child_axes) or len(child_axes) == 0: break
			if cacheAxes: history_child_axes.append(list(child_axes)) # makes a copy
			for index, child_sub_axes in enumerate(child_axes):
				new_child_axes += child_sub_axes
				child_axes[index] = len(child_sub_axes)
			length_of_child_axes = list(set(child_axes))
			if enforceStrict and len(length_of_child_axes) > 1:
				if enforceStrict & 2: raise ValueError(f"Axis {axes_count} is of inconsistent length. {history_child_axes[-1] if cacheAxes else child_axes}")
				break
			yield length_of_child_axes
			child_axes = new_child_axes
			new_child_axes = []

	dimensions = dimensionStepper(_iterable)
	dimensions = map(lambda x: x[0] if len(x) == 1 else x, dimensions)
	minmaxrange = lambda x: range(min(x), max(x)) if len(x) > 0 else range(0)
	dimensions = map(lambda x: minmaxrange(x) if hasattr(x, "__len__") and x == list(minmaxrange(x)) else x, dimensions)
	return tuple(dimensions)
	
def paramify(context, vargs=[], kwargs={}):
	paramType = 0 if "/" in context else 1
	parameters = []
	for param in context:
		match(type(param).__name__):
			case "str":	param, paramDef = param, {}
			case "dict":	param, paramDef = [x for sub in [(k,{"default":v}) for k, v in param.items()] for x in sub]
			case wrongType: raise TypeError(f"Invalid type for 'context'. Only accepts 'str' and 'dict', got: {wrongType}")
		if param == "/":
			if paramType > 0: raise TypeError("Illegal syntax, '/' cannot be used here.")
			paramType = 1
		elif (paramName := regex.search(r"(?:^\*([^*]*)$)|()", param).group(1)) is not None:
			if paramType < 2: paramType = 3
			else: raise TypeError(f"Illegal syntax, {
				"Variable arguments cannot be used here" if paramName else "Positional-Only declaration cannot be used here"
			}.")
			if paramName:	parameters += [inspect.Parameter(paramName,2,**paramDef)]
		elif (paramName := regex.search(r"(?:^\*{2}([^*]*$))|()", param).group(1)) is not None:
			if paramName is None: raise TypeError("Illegal syntax, Variable keyword argument cannot be used without given a name")
			parameters += [inspect.Parameter(paramName,4,**paramDef)]
		else:
			parameters += [inspect.Parameter(param,paramType,**paramDef)]
	signature = inspect.Signature(parameters)
	return signature.bind(*vargs,**kwargs).arguments
	
post()