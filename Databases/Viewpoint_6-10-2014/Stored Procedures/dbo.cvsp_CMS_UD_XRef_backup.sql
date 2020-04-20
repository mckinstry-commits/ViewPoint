SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/**
=========================================================================
	Copyright © 2013 Viewpoint Construction Software (VCS) 
	The TSQL code in this procedure may not be reproduced, modified,
	transmitted or executed without written consent from VCS
=========================================================================
	Title:		Drop prior backup files and back up cross references
	Created:	11/19/2013
	Created by:	Viewpoint Technical Services - BTC
	Function:	Backup ud cross reference tables for a new pull of data
	Revisions:	
**/

CREATE PROCEDURE [dbo].[cvsp_CMS_UD_XRef_backup] 


AS


if exists (select * from sysobjects where name = 'boldxrefAPVendor')
	drop table boldxrefAPVendor;

if exists (select * from sysobjects where name = 'boldxrefARCustomer')
	drop table boldxrefARCustomer;

if exists (select * from sysobjects where name = 'boldxrefCostType')
	drop table boldxrefCostType;
	
if exists (select * from sysobjects where name = 'boldxrefEMCostCodes')
	drop table boldxrefEMCostCodes;
	
if exists (select * from sysobjects where name = 'boldxrefEMCostType')
	drop table boldxrefEMCostType;

if exists (select * from sysobjects where name = 'boldxrefGLAccount')
	drop table boldxrefGLAccount;

if exists (select * from sysobjects where name = 'boldxrefGLAcct')
	drop table boldxrefGLAcct;

if exists (select * from sysobjects where name = 'boldxrefGLAcctTypes')
	drop table boldxrefGLAcctTypes;

if exists (select * from sysobjects where name = 'boldxrefGLJournals')
	drop table boldxrefGLJournals;
	
if exists (select * from sysobjects where name = 'boldxrefGLSubLedger')
	drop table boldxrefGLSubLedger;
	
if exists (select * from sysobjects where name = 'boldxrefJCDept')
	drop table boldxrefJCDept;
	
if exists (select * from sysobjects where name = 'boldxrefJCJobs')
	drop table boldxrefJCJobs;

if exists (select * from sysobjects where name = 'boldxrefPRDedLiab')
	drop table boldxrefPRDedLiab;

if exists (select * from sysobjects where name = 'boldxrefPRDept')
	drop table boldxrefPRDept;

if exists (select * from sysobjects where name = 'boldxrefPREarn')
	drop table boldxrefPREarn;
	
if exists (select * from sysobjects where name = 'boldxrefPhase')
	drop table boldxrefPhase;

if exists (select * from sysobjects where name = 'boldxrefUM')
	drop table boldxrefUM;

if exists (select * from sysobjects where name = 'boldxrefUnion')
	drop table boldxrefUnion;
		
select * into boldxrefAPVendor from budxrefAPVendor;
select * into boldxrefARCustomer from budxrefARCustomer;
select * into boldxrefCostType from budxrefCostType;
select * into boldxrefEMCostCodes from budxrefEMCostCodes;
select * into boldxrefEMCostType from budxrefEMCostType;
select * into boldxrefGLAccount from budxrefGLAccount;
select * into boldxrefGLAcct from budxrefGLAcct;
select * into boldxrefGLAcctTypes from budxrefGLAcctTypes;
select * into boldxrefGLJournals from budxrefGLJournals;
select * into boldxrefGLSubLedger from budxrefGLSubLedger;
select * into boldxrefJCDept from budxrefJCDept;
select * into boldxrefJCJobs from budxrefJCJobs;
select * into boldxrefPRDedLiab from budxrefPRDedLiab;
select * into boldxrefPRDept from budxrefPRDept;
select * into boldxrefPREarn from budxrefPREarn;
select * into boldxrefPhase from budxrefPhase;
select * into boldxrefUM from budxrefUM;
select * into boldxrefUnion from budxrefUnion;
GO
