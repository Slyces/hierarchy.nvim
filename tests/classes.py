from pydantic import BaseModel
from abc import ABC


class ModelInterface(ABC, BaseModel):

    def a(self):
        ...


    def b(self):
        ...


class A(ModelInterface):

    def a(self):
        ...


class B(ModelInterface):

    def b(self):
        ...


class A1(A):
    ...


class A2(A1):
    ...


class A3(A2):

    def b(self):
        ...
