SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE procedure [dbo].[vspPMInterfaceListFillSummary]
/*************************************
* CREATED BY:	TRL 04/19/2011 TK-04412
* MODIFIED By:	GF 05/21/2011 TK-05347
*				TRL 08/22/2011 TK-07623, added code so POCO won't show until original is interfaced
*				GF 09/29/2011 TK-08778 modified exists for POCO ready to interface
*				GPT 12/05/2011 TK-10543 Fill the ACO column for SCO/POCO. 
*				GF 12/12/2011 TK-10926 145249 check POIT for original item for POCO
*				GF 12/20/2011 TK-11086 144955 use an outer apply for SCO/POCO Amount to avoid cartesian
*				GF 01/30/2012 TK-10927 145248 change where clause for POCO to show in list
*				GF 03/08/2012 TK-13086 145859 change join for SCO - Subcontract Change Order - POCO also
*				GF 04/25/2012 TK-14423 146347 change to original subcontract list to show pending subct change orders
*				GP 07/25/2012 TK-16567 146688 changed the original subcontract list to only show type C when header status is pending
*				GF 10/09/2012 TK-18382 147184 display pending POCO for interface if approved
*				AW 2/1/2013 TFS 38468 Refactored to use same db function work center does to return ready to interface
*				AW 8/23/2013 TFS 59373  ID# on ACO Doesn't Show Up
*
*
* USAGE:
* summary list of ACO's, PO's, SL's, MO's and MS Quotes's that are ready to be interfaced
*
* Pass in :
*	PMCo, Project, INCo (used for Material Orders)
*
* Output
*  Returns summary list to be used in 5 columns
*
* Returns
*	Error message and return code
*
*******************************/
(@PMCo bCompany, @Project bJob, @InterfaceType varchar(1), @errmsg varchar(255) output)
as
set nocount on

declare @rcode INT, @INCo bCompany

SET @rcode = 0
SET @INCo = @PMCo

---- must have company
If @PMCo is null
	BEGIN
	select @errmsg = 'Missing PM Company', @rcode=1
	goto vspexit
	END

---- must have project
If @Project IS null
	BEGIN
	select @errmsg = 'Missing PM Project', @rcode=1
	goto vspexit
	END

---- create interface items summary table
Create table  #InterfaceItemsSummary
(
	Interface varchar(30),
	ID varchar(30),
	CO int,
	ACO varchar(30),
	[Description] varchar (120),
	Amount decimal(16,2),
	InterfaceErrors VARCHAR(MAX)
)

INSERT #InterfaceItemsSummary(Interface,ID,CO,ACO,Description,Amount)
SELECT Interface,ID,CO,ACO,Description,Amount
FROM dbo.vfPMReadyToInterface(@PMCo,@Project,@InterfaceType,'Y')

List_Resultset:
--All
If @InterfaceType = '1'
begin
	select Interface, IsNull(ID,ACO) as [ID], [Description],
			CO as [CO Number],
			case when Interface = 'Approved Change Order' then ID else ACO end as [ACO],
			Sum(Amount)as [Amount],
			InterfaceErrors as [Interface Error] 
	from #InterfaceItemsSummary  
	Group by Interface,ID,[Description],CO,ACO, InterfaceErrors
	Order by Interface asc, ID, CO, ACO
end
--Approved Change Orders
If @InterfaceType = '2'
	begin
	select Interface,IsNull(ID,ACO) as ACO,[Description],Sum(Amount)as [Amount],
				InterfaceErrors as [Interface Error] 
	from #InterfaceItemsSummary  
	Group by Interface,ID,ACO,[Description], InterfaceErrors
	Order by ACO, Interface asc
	END
	
--Purchase Orders Original
If @InterfaceType In ('3')
begin
	select Interface,ID as [PO],[Description],Sum(Amount)as [Amount],
				InterfaceErrors as [Interface Error] 
	from #InterfaceItemsSummary  
	Group by Interface,ID,[Description], InterfaceErrors
	Order by ID
END

--Purchase Order Change Orders
If @InterfaceType In ('4')
begin
	select Interface,ID as [PO],[Description], CO as [CO Number],
			ACO, Sum(Amount)as [Amount], 
			InterfaceErrors as [Interface Error] 
	from #InterfaceItemsSummary  
	Group by Interface,ID,CO,[Description], ACO, InterfaceErrors
	Order by ID, CO
END

--Subcontracts Original
If @InterfaceType in ('5')
begin
	select Interface,ID as [Subcontract],[Description],Sum(Amount)as [Amount],
	InterfaceErrors as [Interface Error] 
	from #InterfaceItemsSummary  
	Group by Interface,ID,[Description], InterfaceErrors
	Order by ID
END

--Subcontract CO's
If @InterfaceType in ('6')
begin
	select Interface,ID as [Subcontract],[Description],CO as [CO Number],
			ACO, Sum(Amount)as [Amount],
			InterfaceErrors as [Interface Error] 
	from #InterfaceItemsSummary  
	Group by Interface,ID,CO,[Description],ACO , InterfaceErrors
	Order by ID, CO
END

--Material Orders
If @InterfaceType = '7'
begin
	select Interface,ID as [Matl Order],[Description],Sum(Amount)as [Amount],
			InterfaceErrors as [Interface Error] 
	from #InterfaceItemsSummary  
	Group by Interface,ID,[Description], InterfaceErrors
	Order by ID
END

--MS Quotes
If @InterfaceType = '8'
begin
	select Interface,ID as [Quote],[Description],Sum(Amount)as [Amount],
			InterfaceErrors as [Interface Error] 
	from #InterfaceItemsSummary  
	Group by Interface,ID,[Description], InterfaceErrors
	Order by ID
end
	
vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMInterfaceListFillSummary] TO [public]
GO
