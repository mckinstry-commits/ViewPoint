SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


Create  VIEW [dbo].[vrvSMServiceSiteCustomer]
AS

/***********************************************************************    
Author: 
Scott Alvey
   
Create date: 
09/27/2012 
    
Usage:
As of writing this SM users are able to have either a Customer Service Site type or a 
Job Service Site type. When the type is Customer then the CustGroup and Customer values
are stored in SMServiceSite. But when the type is Job only CustGroup is stored and Customer
has be tracked down by going out to JCCM via JCJM. The catch though is that Customer
is not required on JCCM so there could be instances where the actual Customer is null.
In those situations reports that use this view will mostly likely not bring back records.
Not having a Customer on a JCCM record is considered an extreem edge case and it is 
currently okay for reports not to bring back data on null Customer values. 

A word about naming some fields:
	I need this view to be mostly a select * from SMServiceSite to pick up any custom fields
	placed into that view\form. Since there is already  Customer, CustGroup, and Description
	columns in that view I needed to add new views that act as overrides to those just listed.
	I appended the word 'True' in front of them. Yes we could get into the whole debate of 
	'Truth' and what not, but that would fall within the purview of your conundrums of 
	philosophy. I am here to solve practicle problems ~ Quote from a great engineer.

Parameters:  
N/A

Related reports: 
Multipe SM Work Order and Invoice List reports either directly in the report
or in the view\proc that drives the report.
    
Revision History    
Date  Author  Issue     Description

***********************************************************************/  

select
	ss.*
	, isnull(ss.CustGroup, c.CustGroup) as TrueCustGroup
	, isnull(ss.Customer, c.Customer) as TrueCustomer
	, c.Contract
	, isnull(ss.Description, j.Description) as TrueDescription
from
	SMServiceSite ss
left outer join
	JCJM j on
		ss.JCCo = j.JCCo
		and ss.Job = j.Job
left outer join
	JCCM c on
		j.JCCo = c.JCCo
		and j.Contract = c.Contract
		
GO
GRANT SELECT ON  [dbo].[vrvSMServiceSiteCustomer] TO [public]
GRANT INSERT ON  [dbo].[vrvSMServiceSiteCustomer] TO [public]
GRANT DELETE ON  [dbo].[vrvSMServiceSiteCustomer] TO [public]
GRANT UPDATE ON  [dbo].[vrvSMServiceSiteCustomer] TO [public]
GO
