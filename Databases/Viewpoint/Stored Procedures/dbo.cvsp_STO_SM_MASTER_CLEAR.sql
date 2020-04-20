SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/**
=========================================================================================
Copyright Â© 2013 Viewpoint Construction Software (VCS) 
The TSQL code in this procedure may not be reproduced, copied, modified,
or executed without written consent from VCS.
=========================================================================================
	Title:	Clear Viewpoint SM Master Tables	
	Created: 2013
	Created by:	VCS Technical Services - Brenda Ackerson
	Revisions:	
		1. 

	Notes:		
**/

CREATE PROCEDURE [dbo].[cvsp_STO_SM_MASTER_CLEAR] 
(@Co bCompany)

AS 

/* DISABLE FOREIGN KEYS */
EXEC cvsp_Disable_Foreign_Keys;

/** DECLARE AND SET PARAMETERS **/
DECLARE @CustGroup tinyint	
SET @CustGroup=(SELECT CustGroup FROM bHQCO WHERE HQCo=@Co)

/** BACKUP SM MASTER TABLES **/

/** SM Service Site Contacts **/
IF OBJECT_ID('vSMServiceSiteContact_bak','U') IS NOT NULL
BEGIN
	DROP TABLE vSMServiceSiteContact_bak
END;
BEGIN
	SELECT * INTO vSMServiceSiteContact_bak FROM vSMServiceSiteContact
END;

/** SM Service Sites **/
IF OBJECT_ID('vSMServiceSite_bak','U') IS NOT NULL
BEGIN
	DROP TABLE vSMServiceSite_bak
END;
BEGIN
	SELECT * INTO vSMServiceSite_bak FROM vSMServiceSite
END;

/** SM Customers **/
IF OBJECT_ID('vSMCustomer_bak','U') IS NOT NULL
BEGIN
	DROP TABLE vSMCustomer_bak
END;
BEGIN
	SELECT * INTO vSMCustomer_bak FROM vSMCustomer
END;

/** SM Technicians **/
IF OBJECT_ID('vSMTechnician_bak','U') IS NOT NULL
BEGIN
	DROP TABLE vSMTechnician_bak
END;
BEGIN
	SELECT * INTO vSMTechnician_bak FROM vSMTechnician
END;


/* DELETE SM MASTER & SETUP TABLES FOR @Co COMPANY */

BEGIN

	/** SM Service Site Contact **/
	ALTER TABLE vSMServiceSiteContact DISABLE TRIGGER ALL;
	BEGIN TRAN
		DELETE vSMServiceSiteContact
		WHERE vSMServiceSiteContact.SMCo=@Co
	COMMIT TRAN
	CHECKPOINT;
	WAITFOR DELAY '00:00:02.000';
	ALTER TABLE vSMServiceSiteContact ENABLE TRIGGER ALL;

	/** SM Service Sites **/
	ALTER TABLE vSMServiceSite DISABLE TRIGGER ALL;
	BEGIN TRAN
		DELETE vSMServiceSite
		WHERE vSMServiceSite.SMCo=@Co
	COMMIT TRAN
	CHECKPOINT;
	WAITFOR DELAY '00:00:02.000';
	ALTER TABLE vSMServiceSite ENABLE TRIGGER A

	/** SM Customers **/
	ALTER TABLE vSMCustomer DISABLE TRIGGER ALL;
	BEGIN TRAN
		DELETE vSMCustomer
		WHERE vSMCustomer.CustGroup=@CustGroup
	COMMIT TRAN
	CHECKPOINT;
	WAITFOR DELAY '00:00:02.000';
	ALTER TABLE vSMCustomer ENABLE TRIGGER ALL;

	/** SM Technicians **/
	ALTER TABLE vSMTechnician DISABLE TRIGGER ALL;
	BEGIN TRAN
		DELETE vSMTechnician
		WHERE vSMTechnician.SMCo=@Co
	COMMIT TRAN
	CHECKPOINT;
	WAITFOR DELAY '00:00:02.000';
	ALTER TABLE vSMTechnician ENABLE TRIGGER ALL;

		PRINT 'SM MASTER TABLES HAVE BEEN DELETED FOR SPECIFIED COMPANY.'
		
END;


/* ENABLE FOREIGN KEYS */
EXEC cvsp_Enable_Foreign_Keys;	

		
/** RECORD COUNT **/ 
--declare @Co bCompany set @Co=
SELECT COUNT(*) AS SMServiceSiteContact_Count FROM vSMServiceSiteContact WHERE SMCo=@Co; 
SELECT COUNT(*) AS SMServiceSite_Count FROM vSMServiceSite WHERE SMCo=@Co; 
SELECT COUNT(*) AS SMCustomer_Count FROM vSMCustomer WHERE SMCo=@Co; 
SELECT COUNT(*) AS SMTechnician_Count FROM vSMTechnician WHERE SMCo=@Co; 


/** DATA REVIEW 
--declare @Co bCompany set @Co=
SELECT * FROM vSMServiceSiteContact WHERE SMCo=@Co; 
SELECT * FROM vSMServiceSite WHERE SMCo=@Co; 
SELECT * FROM vSMCustomer WHERE SMCo=@Co; 
SELECT * FROM vSMTechnician WHERE SMCo=@Co; 
**/

GO
