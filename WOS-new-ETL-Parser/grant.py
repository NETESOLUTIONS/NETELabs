# coding=utf-8

'''
Function:   this is a class file for publications to save its value in the form of an object


https://github.com/NETESOLUTIONS/NETELabs/blob/master/WOS-new-ETL-Parser/.readme
Author: 	Akshat Maltare
Date:		03/24/2018
Changes:
'''
import xml.etree.cElementTree as ET
class grant:

    def __init__(self):
        #self.r_publication_seq = 0
        self.source_id= ''
        self.funding_ack=''
        self.grant_agency=''
        self.id=None
        self.grant_number=''
        self.funding_ack=''
