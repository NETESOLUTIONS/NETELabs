# coding=utf-8

'''
Function:   this is a class file for addresses to save its value in the form of an object

https://github.com/NETESOLUTIONS/NETELabs/blob/master/WOS-new-ETL-Parser/.readme
USAGE:  	python address.py
Author: 	Akshat Maltare
Date:		03/24/2018
Changes:
'''

class address:
    def __init__(self):
        self.id={}
        self.source_id={}
        self.addr_name={}
        self.organization={}
        self.sub_organization={}
        self.city={}
        self.country={}
        self.zip_code={}
