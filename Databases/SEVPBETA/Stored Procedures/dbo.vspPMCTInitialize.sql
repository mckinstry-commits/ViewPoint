SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*********************************************/
CREATE proc [dbo].[vspPMCTInitialize]
/*********************************************
 * Created By:	GF 05/19/2009 - issue #24641
 * Modified By:	GF 08/10/2010 - issue #140980
 *				GF 03/18/2011 - TK-02604 TK-03298
 *				DAN SO 03/31/2011 - TK-03642
 *				GF 05/02/2011 TK-04388 CCO
 *				DAN SO 01/12/2012 - TK-11052 - PO
 *				TRL 08/02/2012  TK-1816  Add Doc Cat "SBMTL" and "SBMTLPCKG"
 *				TRL 08/07/2012 TK-16811 Add Doc Category POCO
 *				GP	09/15/2012 - TK-17949 Changed descriptions for SUBMIT and SBMTL
 *				TRL  01/03/2013 - TK-20499 add notes Doc Categories PO/PURCHASE and POCO and PURCASECO
*
*
 * Initializes PM document categories (PMCT) and
 * PM Document Category Overrides
 *
 *
 * Pass:
 *	Nothing
 *
 * Success returns:
 *	0
 *
 * Error returns:
 *	1
 **************************************/
as
set nocount on

declare @rcode int

select @rcode = 0

/*********************
* Intitalize PMCT    *
**********************/

/***********************************************************************************************
Why we have duplicate Doc Categories PO/PURCHASE and POCO and PURCHASECO
1.  Stored procedure vspPMCTInitialize initializes PM Document Categories "POCO" and "PURCHASECO".
2.  PM Document Type Form;  Doc Category column value validates "POCO".  This value comes from 
DD Combo Box "PMDocCategory" which has combox item Purchase Order Change Order with a value of "POCO".
3.  PM PO Change Order form Doc Category value is hard coded = "PURCHASECO".   
4.  PM Projects (Firm Tab)/(Task Button (Assign Distribution Defaults) program which updates 
PMProjDefDistDocType Doc Category with a Value of "POCO".
vspPMProjDefDistIntoPMDistributionForPOCONum hard code the link between PURCHASECO and POCO
5.  Doc Category Valiation procedures will always validate "POCO" and "PURCHASECO" has valid document types.
6.  PM Send Search Documents, PMSendDocuments, PM Create and Send Settings are coded to use "PURCHASECO".
7.  Apply above for PO/PURCHASE and vspPMProjDefDistIntoPMDistributionForPOCONum 
***************************************************************************************************/

---- populate document categories tables with standard categories
---- RFI
if not exists(select 1 from dbo.bPMCT where DocCat='RFI')
	begin
	insert into bPMCT (DocCat, Description)
	values('RFI', 'Request for Information')
	end
---- RFQ
if not exists(select 1 from dbo.bPMCT where DocCat='RFQ')
	begin
	insert into bPMCT (DocCat, Description)
	values('RFQ', 'Request for Quote')
	end
---- ACO
if not exists(select 1 from dbo.bPMCT where DocCat='ACO')
	begin
	insert into bPMCT (DocCat, Description)
	values('ACO', 'Approved Change Order')
	end
---- PCO
if not exists(select 1 from dbo.bPMCT where DocCat='PCO')
	begin
	insert into bPMCT (DocCat, Description)
	values('PCO', 'Pending Change Order')
	end
---- DRAWING
if not exists(select 1 from dbo.bPMCT where DocCat='DRAWING')
	begin
	insert into bPMCT (DocCat, Description)
	values('DRAWING', 'Drawing Log')
	end
---- INSPECT
if not exists(select 1 from dbo.bPMCT where DocCat='INSPECT')
	begin
	insert into bPMCT (DocCat, Description)
	values('INSPECT', 'Inspection Log')
	end
---- OTHER
if not exists(select 1 from dbo.bPMCT where DocCat='OTHER')
	begin
	insert into bPMCT (DocCat, Description)
	values('OTHER', 'Other Document')
	end
---- SUBMIT
if not exists(select 1 from dbo.bPMCT where DocCat='SUBMIT')
	begin
	insert into bPMCT (DocCat, Description)
	values('SUBMIT', 'Submittals - 6.5')
	end
---- SUBMIT
if not exists(select 1 from dbo.bPMCT where DocCat='TEST')
	begin
	insert into bPMCT (DocCat, Description)
	values('TEST', 'Test Log')
	end
---- MTG
if not exists(select 1 from dbo.bPMCT where DocCat='MTG')
	begin
	insert into bPMCT (DocCat, Description)
	values('MTG', 'Meeting Minutes')
	end
---- TRANSMIT
if not exists(select 1 from dbo.bPMCT where DocCat='TRANSMIT')
	begin
	insert into bPMCT (DocCat, Description)
	values('TRANSMIT', 'Transmittal')
	end
---- PUNCH
if not exists(select 1 from dbo.bPMCT where DocCat='PUNCH')
	begin
	insert into bPMCT (DocCat, Description)
	values('PUNCH', 'Punch List')
	end
---- PURCHASE
if not exists(select 1 from dbo.bPMCT where DocCat='PURCHASE')
	begin
	insert into bPMCT (DocCat, Description)
	values('PURCHASE', 'Purchase Order')
	end
---- SUB
if not exists(select 1 from dbo.bPMCT where DocCat='SUB')
	begin
	insert into bPMCT (DocCat, Description)
	values('SUB', 'Subcontract')
	end
---- SUBITEM
if not exists(select 1 from dbo.bPMCT where DocCat='SUBITEM')
	begin
	insert into bPMCT (DocCat, Description)
	values('SUBITEM', 'Subcontract with Items')
	end
---- PROJNOTES
if not exists(select 1 from dbo.bPMCT where DocCat='PROJNOTES')
	begin
	insert into bPMCT (DocCat, Description)
	values('PROJNOTES', 'Project Notes')
	end
---- DAILYLOG
if not exists(select 1 from dbo.bPMCT where DocCat='DAILYLOG')
	begin
	insert into bPMCT (DocCat, Description)
	values('DAILYLOG', 'Daily Log')
	end
	
---- ISSUE #140980
if not exists(select 1 from dbo.bPMCT where DocCat='ISSUE')
	begin
	insert into bPMCT (DocCat, Description)
	values('ISSUE', 'Issue')
	end

---- TK-02604
if NOT EXISTS(select 1 from dbo.bPMCT where DocCat='SUBCO')
	begin
	insert into bPMCT (DocCat, Description)
	values('SUBCO', 'SUBCO')
	end

---- TK-03298
if NOT EXISTS(select 1 from dbo.bPMCT where DocCat='COR')
	begin
	insert into bPMCT (DocCat, Description)
	values('COR', 'COR')
	end

---- TK-03642
if NOT EXISTS(select 1 from dbo.bPMCT where DocCat='PURCHASECO')
	begin
	insert into bPMCT (DocCat, Description)
	values('PURCHASECO', 'PO Change Order')
	end
	

if NOT EXISTS(select 1 from dbo.bPMCT where DocCat='POCO')
	begin
	insert into bPMCT (DocCat, Description)
	values('POCO', 'PO Change Order')
	end

----TK-04388
if NOT EXISTS(select 1 from dbo.bPMCT where DocCat='CCO')
	begin
	insert into bPMCT (DocCat, Description)
	values('CCO', 'Contract Change Order')
	END
	
---- TK-11052
if NOT EXISTS(select 1 from dbo.bPMCT where DocCat='PO')
	begin
	insert into bPMCT (DocCat, Description)
	values('PO', 'Purchase Order')
	END
	
---- TK-1816
if NOT EXISTS(select 1 from dbo.bPMCT where DocCat='SBMTL')
	begin
	insert into bPMCT (DocCat, Description)
	values('SBMTL', 'Submittals')
	end
	
---- TK-1816
if NOT EXISTS(select 1 from dbo.bPMCT where DocCat='SBMTLPCKG')
	begin
	insert into bPMCT (DocCat, Description)
	values('SBMTLPCKG', 'Submittal Package')
	end	

/*********************
* Intitalize PMCU    *
**********************/

insert into dbo.bPMCU (DocCat, Inactive, UseStdCCList, UseStdSubject, UseStdFileName)
select c.DocCat, 'N', 'Y', 'Y', 'Y'
from dbo.bPMCT c
where not exists(select 1 from dbo.bPMCU o where c.DocCat = o.DocCat)


/*********************
* Intitalize PMLS    *
**********************/

---- firm number
insert into bPMLS (DocCat, TableName, ColumnName, ColumnAlias, ColumnType)
select c.DocCat, 'PMPF', 'FirmNumber', 'Firm', 'Standard'
from dbo.bPMCT c
where not exists(select 1 from dbo.bPMLS o where c.DocCat = o.DocCat and o.TableName = 'PMPF' and o.ColumnName = 'FirmNumber')

---- firm name
insert into bPMLS (DocCat, TableName, ColumnName, ColumnAlias, ColumnType)
select c.DocCat, 'PMFM', 'FirmName', 'Firm Name', 'Standard'
from dbo.bPMCT c
where not exists(select 1 from dbo.bPMLS o where c.DocCat = o.DocCat and o.TableName = 'PMFM' and o.ColumnName = 'FirmName')

---- contact code
insert into bPMLS (DocCat, TableName, ColumnName, ColumnAlias, ColumnType)
select c.DocCat, 'PMPF', 'ContactCode', 'Contact', 'Standard'
from dbo.bPMCT c
where not exists(select 1 from dbo.bPMLS o where c.DocCat = o.DocCat and o.TableName = 'PMPF' and o.ColumnName = 'ContactCode')

---- sort name
insert into bPMLS (DocCat, TableName, ColumnName, ColumnAlias, ColumnType)
select c.DocCat, 'PMPM', 'SortName', 'Sort Name', 'Standard'
from dbo.bPMCT c
where not exists(select 1 from dbo.bPMLS o where c.DocCat = o.DocCat and o.TableName = 'PMPM' and o.ColumnName = 'SortName')

---- contact name
insert into bPMLS (DocCat, TableName, ColumnName, ColumnAlias, ColumnType)
select c.DocCat, 'PMPM', 'FirstName, MiddleInit, LastName', 'Contact Name', 'Standard'
from dbo.bPMCT c
where not exists(select 1 from dbo.bPMLS o where c.DocCat = o.DocCat and o.TableName = 'PMPM' and o.ColumnName = 'FirstName, MiddleInit, LastName')


			

bspexit:
   	return @rcode



GO
GRANT EXECUTE ON  [dbo].[vspPMCTInitialize] TO [public]
GO
