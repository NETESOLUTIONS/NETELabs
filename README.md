# Welcome to Nete Labs

NETE Labs (@netelabs) at NET ESOLUTIONS CORPORATION (NETE®) is a pilot research unit developing expertise in digital technologies, research analytics and business intel. NETE Labs is a nascent project- the concept took shape around July/Aug 2016. NETE Labs is staffed by full-time employees of NETE(@netesolutions) who have common interests in challenging problems typically outside the immediate scope of their assigned responsibilities. These good folks belong to different teams within NETE and volunteer their time and effort. NETE Labs supports the Open Source way and makes every effort to share its code and offer appropriate attribution. Being a corporation with obligations to its customers, this isn't always possible though. NETE Labs collaborates with academia and industry. Expressions of interest in collaborations are welcomed (email: netelabs@nete.com).

Several projects are currently active and involve collaborators from outside NETE. At present, they are mostly centered around the use of administrative, bibliographic, clinical trials, and other public records to enable studies of biomedical research in particular. The work of [Williams et al](http://dx.doi.org/10.1016/j.cell.2015.09.007) is inspirational in this regard and  and a related NETE Labs project is being archived on the [Open Science Framework](https://osf.io/) and will become public once a manuscript is submitted Relevant key words/phrases are 'bibliometrics', 'research evaluation', 'linked datasets', 'administrative records', 'patents', 'clinical trials', 'clinical guidelines', 'research awards', and 'researcher profiling'.

In April 2017, we released Python code that we wrote to parse Web of Science (WoS) XML data. A version of this code has been successfully used to load the Web of Science Core Collection (around 64.5 million publications at last count plus millions of rows in related tables) into a PostgreSQL 9.6 database. WoS data is made
available as a collection of XML files. The procedure used at NETE involves splitting each XML file into smaller XML files of 20,000 records each and then feeding the split XML files to the WoS XML parser, which extracts the elements of interest and loads them into 9 csv files. These are loaded into PostgreSQL tables using a loading script  in the parser.




