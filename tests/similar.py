from tests.classes import B

class NotBaseModel:

    def dict(self):
        ...

    def a(self):
        ...

    def b(self):
        ...


class A(NotBaseModel):
    ...


class B1(B):

    def b(self):
        ...

b = B1()
b.b()
