SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/***********************************
* Created:		Gabriel Piltzer 02/05/2008
* 
* Issue 126939
* This script adds the procedure vspPMImportPMUDDefault.
************************************/

CREATE PROC [dbo].[vspPMImportPMUDDefault]

  /*************************************
  * CREATED BY:		GP 01/27/2009
  * MODIFIED BY:	GP 11/03/2009 - issue 135149, changed ViewpointDefault insert value for Item tab - BillType field
  *					GP 11/18/2009 - issue 136627 added RecColumn position for SMRetgPct
  *					GP 12/22/2009 - Issue 136125 added BegPos & EndPos to CostType-Costs record.
  *
  *		Copies standard column info needed
  *		for PMImportTemplateDetail from
  *		standard tables to PMUD. Also sets defaults
  *		for upload to PMUD columns.
  *
  *		Input Parameters:
  *			Template
  *    
  *		Output Parameters:
  *			rcode - 0 Success
  *					1 Failure
  *			msg - Return Message
  *		
  **************************************/
	(@Template varchar(10) = null, @Description bDesc = null, @msg varchar(255) output)
	as
	set nocount on


declare @rcode smallint, @ImportRoutine varchar(20)
		
select @rcode = 0

if @Template is null
begin
	select @msg = 'Missing Template!', @rcode = 1
	goto vspexit
end

begin try
	begin transaction

	select @ImportRoutine = ImportRoutine from PMUT with (nolock) where Template=@Template

	--Insert template for record type's into PMUR--
	insert bPMUR(Template, Description, ContractItemID, PhaseID, CostTypeID, SubcontractDetailID, MaterialDetailID,
		EstimateInfoID, ResourceDetailID)
	select @Template, @Description, 1, 2, 3, 4, 5, 6, 7
	where not exists(select top 1 1 from PMUR with (nolock) where Template=@Template) 

	--Insert Item Records into bPMUD--
	if not exists(select top 1 1 from PMUD with (nolock) where Template=@Template and RecordType='Item')
	begin
		insert bPMUD(Template, RecordType, Seq, Form, ColumnName, ColDesc, Required, RecColumn, ViewpointDefault, 
			ViewpointDefaultValue, Datatype, Hidden, BegPos, EndPos)
		values(@Template, 'Item', 1, 'JCCI', 'RecordType', 'Record Type', 'Y', 1, 'N', null, null, 'N', 1, 2)

		insert bPMUD(Template, RecordType, Seq, Form, ColumnName, ColDesc, Required, RecColumn, ViewpointDefault, ViewpointDefaultValue, Datatype, Hidden)
		values(@Template, 'Item', 2, 'JCCI', 'ProjectCode', 'Project Code', 'N', 2, 'N', null, null, 'N')

		insert bPMUD(Template, RecordType, Seq, Form, ColumnName, ColDesc, Required, RecColumn, ViewpointDefault, 
			ViewpointDefaultValue, Datatype, Hidden, BegPos, EndPos)
		values(@Template, 'Item', 3, 'JCCI', 'Item', 'Item', 'Y', 3, 'N', null, 'bContractItem', 'N', 14, 24)

		insert bPMUD(Template, RecordType, Seq, Form, ColumnName, ColDesc, Required, RecColumn, ViewpointDefault, ViewpointDefaultValue, Datatype, Hidden)
		values(@Template, 'Item', 4, 'JCCI', 'SIRegion', 'SI Region', 'Y', 4, 'Y', '**PMUT.DefaultSIRegion', 'varchar(6)', 'N')

		insert bPMUD(Template, RecordType, Seq, Form, ColumnName, ColDesc, Required, RecColumn, ViewpointDefault, ViewpointDefaultValue, Datatype, Hidden)
		values(@Template, 'Item', 5, 'JCCI', 'SICode', 'SI Code', 'Y', 5, 'N', null, 'varchar(16)', 'N')

		insert bPMUD(Template, RecordType, Seq, Form, ColumnName, ColDesc, Required, RecColumn, ViewpointDefault, 
			ViewpointDefaultValue, Datatype, Hidden, BegPos, EndPos)
		values(@Template, 'Item', 6, 'JCCI', 'Description', 'Description', 'Y', 6, 'N', null, 'bItemDesc', 'N', 25, 55)

		insert bPMUD(Template, RecordType, Seq, Form, ColumnName, ColDesc, Required, RecColumn, ViewpointDefault, 
			ViewpointDefaultValue, Datatype, Hidden, BegPos, EndPos)
		values(@Template, 'Item', 7, 'JCCI', 'Units', 'Units', 'Y', 7, 'Y', 0, 'bUnits', 'N', 56, 69)

		insert bPMUD(Template, RecordType, Seq, Form, ColumnName, ColDesc, Required, RecColumn, ViewpointDefault, 
			ViewpointDefaultValue, Datatype, Hidden, BegPos, EndPos)
		values(@Template, 'Item', 8, 'JCCI', 'UM', 'Unit of Measure', 'Y', 8, 'N', null, 'bUM', 'N', 70, 74)

		insert bPMUD(Template, RecordType, Seq, Form, ColumnName, ColDesc, Required, RecColumn, ViewpointDefault, 
			ViewpointDefaultValue, Datatype, Hidden, BegPos, EndPos)
		values(@Template, 'Item', 9, 'JCCI', 'UnitCost', 'Unit Cost', 'Y', 9, 'Y', 0, 'bUnitCost', 'N', 75, 88)

		insert bPMUD(Template, RecordType, Seq, Form, ColumnName, ColDesc, Required, RecColumn, ViewpointDefault, ViewpointDefaultValue, Datatype, Hidden)
		values(@Template, 'Item', 10, 'JCCI', 'Amount', 'Amount', 'Y', 10, 'Y', '**Units x UnitCost', 'bDollar', 'N')

		insert bPMUD(Template, RecordType, Seq, Form, ColumnName, ColDesc, Required, RecColumn, ViewpointDefault, ViewpointDefaultValue, Datatype, Hidden)
		values(@Template, 'Item', 11, 'JCCI', 'RetainPCT', 'Retainage %', 'Y', 11, 'Y', '**Upload Retainage %', 'bPct', 'N')

		insert bPMUD(Template, RecordType, Seq, Form, ColumnName, ColDesc, Required, RecColumn, ViewpointDefault, ViewpointDefaultValue, Datatype, Hidden)
		values(@Template, 'Item', 12, 'JCCI', 'Notes', 'Notes', 'Y', 12, 'N', null, 'varchar(max)', 'N')

		insert bPMUD(Template, RecordType, Seq, Form, ColumnName, ColDesc, Required, RecColumn, ViewpointDefault, ViewpointDefaultValue, Datatype, Hidden)
		values(@Template, 'Item', 13, 'JCCI', 'BillDescription', 'Bill Description', 'N', null, 'N', '**Item Description', 'bItemDesc', 'N')

		insert bPMUD(Template, RecordType, Seq, Form, ColumnName, ColDesc, Required, RecColumn, ViewpointDefault, ViewpointDefaultValue, Datatype, Hidden)
		values(@Template, 'Item', 14, 'JCCI', 'BillGroup', 'Bill Group', 'N', null, 'N', null, 'bBillingGroup', 'N')

		--135149 changed ViewpointDefault insert value from 'B' to '**JCCO.DefaultBillType'
		insert bPMUD(Template, RecordType, Seq, Form, ColumnName, ColDesc, Required, RecColumn, ViewpointDefault, ViewpointDefaultValue, Datatype, Hidden)
		values(@Template, 'Item', 15, 'JCCI', 'BillType', 'Bill Type', 'N', 30, 'Y', '**JCCO.DefaultBillType', 'bBillType', 'N')

		insert bPMUD(Template, RecordType, Seq, Form, ColumnName, ColDesc, Required, RecColumn, ViewpointDefault, ViewpointDefaultValue, Datatype, Hidden)
		values(@Template, 'Item', 16, 'JCCI', 'InitAsZero', 'Init as Zero', 'Y', 13, 'Y', 'N', 'bYN', 'N')

		insert bPMUD(Template, RecordType, Seq, Form, ColumnName, ColDesc, Required, RecColumn, ViewpointDefault, ViewpointDefaultValue, Datatype, Hidden)
		values(@Template, 'Item', 17, 'JCCI', 'InitSubs', 'Init Subs', 'Y', 14, 'Y', 'Y', 'bYN', 'N')

		insert bPMUD(Template, RecordType, Seq, Form, ColumnName, ColDesc, Required, RecColumn, ViewpointDefault, ViewpointDefaultValue, Datatype, Hidden)
		values(@Template, 'Item', 18, 'JCCI', 'MarkUpRate', 'Mark Up Rate', 'Y', 15, 'Y', 0, 'bRate', 'N')

		insert bPMUD(Template, RecordType, Seq, Form, ColumnName, ColDesc, Required, RecColumn, ViewpointDefault, ViewpointDefaultValue, Datatype, Hidden)
		values(@Template, 'Item', 19, 'JCCI', 'StartMonth', 'Start Month', 'N', null, 'N', null, 'bMonth', 'N')

		insert bPMUD(Template, RecordType, Seq, Form, ColumnName, ColDesc, Required, RecColumn, ViewpointDefault, ViewpointDefaultValue, Datatype, Hidden)
		values(@Template, 'Item', 20, 'JCCI', 'TaxCode', 'Tax Code', 'N', null, 'N', null, 'bTaxCode', 'N')
	end

	--Insert Phase Records into bPMUD--
	if not exists(select top 1 1 from PMUD with (nolock) where Template=@Template and RecordType='Phase')
	begin
		insert bPMUD(Template, RecordType, Seq, Form, ColumnName, ColDesc, Required, RecColumn, ViewpointDefault, 
			ViewpointDefaultValue, Datatype, Hidden, BegPos, EndPos)
		values(@Template, 'Phase', 1, 'JCJP', 'RecordType', 'Record Type', 'Y', 1, 'N', null, null, 'N', 1, 2)

		insert bPMUD(Template, RecordType, Seq, Form, ColumnName, ColDesc, Required, RecColumn, ViewpointDefault, ViewpointDefaultValue, Datatype, Hidden)
		values(@Template, 'Phase', 2, 'JCJP', 'ProjectCode', 'Project Code', 'N', 2, 'N', null, null, 'N')

		insert bPMUD(Template, RecordType, Seq, Form, ColumnName, ColDesc, Required, RecColumn, ViewpointDefault, 
			ViewpointDefaultValue, Datatype, Hidden, BegPos, EndPos)
		values(@Template, 'Phase', 3, 'JCJP', 'Item', 'Item', 'Y', 3, 'N', null, 'bContractItem', 'N', 14, 24)

		insert bPMUD(Template, RecordType, Seq, Form, ColumnName, ColDesc, Required, RecColumn, ViewpointDefault, 
			ViewpointDefaultValue, Datatype, Hidden, BegPos, EndPos)
		values(@Template, 'Phase', 4, 'JCJP', 'Phase', 'Phase', 'Y', 4, 'N', null, 'bPhase', 'N', 25, 39)

		insert bPMUD(Template, RecordType, Seq, Form, ColumnName, ColDesc, Required, RecColumn, ViewpointDefault, 
			ViewpointDefaultValue, Datatype, Hidden, BegPos, EndPos)
		values(@Template, 'Phase', 5, 'JCJP', 'Description', 'Description', 'Y', 5, 'N', null, 'bItemDesc', 'N', 40, 70)

		insert bPMUD(Template, RecordType, Seq, Form, ColumnName, ColDesc, Required, RecColumn, ViewpointDefault, ViewpointDefaultValue, Datatype, Hidden)
		values(@Template, 'Phase', 6, 'JCJP', 'Notes', 'Notes', 'Y', 6, 'N', null, 'varchar(max)', 'N')

		insert bPMUD(Template, RecordType, Seq, Form, ColumnName, ColDesc, Required, RecColumn, ViewpointDefault, ViewpointDefaultValue, Datatype, Hidden)
		values(@Template, 'Phase', 7, 'JCJP', 'ActiveYN', 'Active', 'Y', 7, 'Y', 'Y', 'bYN', 'N')

		insert bPMUD(Template, RecordType, Seq, Form, ColumnName, ColDesc, Required, RecColumn, ViewpointDefault, ViewpointDefaultValue, Datatype, Hidden)
		values(@Template, 'Phase', 8, 'JCJP', 'InsCode', 'Insurance Code', 'N', null, 'N', null, 'bInsCode', 'N')

		insert bPMUD(Template, RecordType, Seq, Form, ColumnName, ColDesc, Required, RecColumn, ViewpointDefault, ViewpointDefaultValue, Datatype, Hidden)
		values(@Template, 'Phase', 9, 'JCJP', 'ProjMinPct', 'Project Minimum Percent', 'N', null, 'Y', 0, 'bPct', 'N')
	end

	--Insert CostType Records into bPMUD--
	if not exists(select top 1 1 from PMUD with (nolock) where Template=@Template and RecordType='CostType')
	begin
		insert bPMUD(Template, RecordType, Seq, Form, ColumnName, ColDesc, Required, RecColumn, ViewpointDefault, 
			ViewpointDefaultValue, Datatype, Hidden, BegPos, EndPos)
		values(@Template, 'CostType', 1, 'JCCH', 'RecordType', 'Record Type', 'Y', 1, 'N', null, null, 'N',1 , 2)

		insert bPMUD(Template, RecordType, Seq, Form, ColumnName, ColDesc, Required, RecColumn, ViewpointDefault, ViewpointDefaultValue, Datatype, Hidden)
		values(@Template, 'CostType', 2, 'JCCH', 'ProjectCode', 'Project Code', 'N', 2, 'N', null, null, 'N')

		insert bPMUD(Template, RecordType, Seq, Form, ColumnName, ColDesc, Required, RecColumn, ViewpointDefault, 
			ViewpointDefaultValue, Datatype, Hidden, BegPos, EndPos)
		values(@Template, 'CostType', 3, 'JCCH', 'Item', 'Item', 'Y', 3, 'N', null, 'varchar(16)', 'N', 14, 24)

		insert bPMUD(Template, RecordType, Seq, Form, ColumnName, ColDesc, Required, RecColumn, ViewpointDefault, 
			ViewpointDefaultValue, Datatype, Hidden, BegPos, EndPos)
		values(@Template, 'CostType', 4, 'JCCH', 'Phase', 'Phase', 'Y', 4, 'N', null, 'bPhase', 'N', 25, 39)	

		insert bPMUD(Template, RecordType, Seq, Form, ColumnName, ColDesc, Required, RecColumn, ViewpointDefault, 
			ViewpointDefaultValue, Datatype, Hidden, BegPos, EndPos)
		values(@Template, 'CostType', 5, 'JCCH', 'CostType', 'Cost Type', 'Y', 5, 'N', null, 'bJCCType', 'N', 40, 42)

		insert bPMUD(Template, RecordType, Seq, Form, ColumnName, ColDesc, Required, RecColumn, ViewpointDefault, 
			ViewpointDefaultValue, Datatype, Hidden, BegPos, EndPos)
		values(@Template, 'CostType', 6, 'JCCH', 'Units', 'Units', 'Y', 6, 'Y', 0, 'bUnits', 'N', 42, 55)

		insert bPMUD(Template, RecordType, Seq, Form, ColumnName, ColDesc, Required, RecColumn, ViewpointDefault, 
			ViewpointDefaultValue, Datatype, Hidden, BegPos, EndPos)
		values(@Template, 'CostType', 7, 'JCCH', 'UM', 'Unit of Measure', 'Y', 7, 'N', null, 'bUM', 'N', 56, 60)

		insert bPMUD(Template, RecordType, Seq, Form, ColumnName, ColDesc, Required, RecColumn, ViewpointDefault, 
			ViewpointDefaultValue, Datatype, Hidden, BegPos, EndPos)
		values(@Template, 'CostType', 8, 'JCCH', 'Hours', 'Hours', 'Y', 8, 'Y', 0, 'bHrs', 'N', 61, 74)

		insert bPMUD(Template, RecordType, Seq, Form, ColumnName, ColDesc, Required, RecColumn, ViewpointDefault, 
			ViewpointDefaultValue, Datatype, Hidden, BegPos, EndPos)
		values(@Template, 'CostType', 9, 'JCCH', 'Costs', 'Costs', 'Y', 9, 'Y', 0, 'bDollar', 'N', 75, 88)

		insert bPMUD(Template, RecordType, Seq, Form, ColumnName, ColDesc, Required, RecColumn, ViewpointDefault, ViewpointDefaultValue, Datatype, Hidden)
		values(@Template, 'CostType', 10, 'JCCH', 'BillFlag', 'Bill Flag', 'Y', 10, 'Y', 'C', 'char(1)', 'N')

		insert bPMUD(Template, RecordType, Seq, Form, ColumnName, ColDesc, Required, RecColumn, ViewpointDefault, ViewpointDefaultValue, Datatype, Hidden)
		values(@Template, 'CostType', 11, 'JCCH', 'ItemUnitFlag', 'Item Unit Flag', 'Y', 11, 'Y', 'N', 'bYN', 'N')

		insert bPMUD(Template, RecordType, Seq, Form, ColumnName, ColDesc, Required, RecColumn, ViewpointDefault, ViewpointDefaultValue, Datatype, Hidden)
		values(@Template, 'CostType', 12, 'JCCH', 'PhaseUnitFlag', 'Phase Unit Flag', 'Y', 12, 'Y', 'N', 'bYN', 'N')

		insert bPMUD(Template, RecordType, Seq, Form, ColumnName, ColDesc, Required, RecColumn, ViewpointDefault, ViewpointDefaultValue, Datatype, Hidden)
		values(@Template, 'CostType', 13, 'JCCH', 'Notes', 'Notes', 'Y', 13, 'N', null, 'varchar(max)', 'N')

		insert bPMUD(Template, RecordType, Seq, Form, ColumnName, ColDesc, Required, RecColumn, ViewpointDefault, ViewpointDefaultValue, Datatype, Hidden)
		values(@Template, 'CostType', 14, 'JCCH', 'ActiveYN', 'Active', 'N', 14, 'Y', 'Y', 'bYN', 'N')

		insert bPMUD(Template, RecordType, Seq, Form, ColumnName, ColDesc, Required, RecColumn, ViewpointDefault, ViewpointDefaultValue, Datatype, Hidden)
		values(@Template, 'CostType', 15, 'JCCH', 'BuyOutYN', 'Buy Out', 'N', 15, 'Y', 'N', 'bYN', 'N')
	end

	--Insert Subcontract Detail Records into bPMUD--
	if not exists(select top 1 1 from PMUD with (nolock) where Template=@Template and RecordType='SubDetail')
	begin
		insert bPMUD(Template, RecordType, Seq, Form, ColumnName, ColDesc, Required, RecColumn, ViewpointDefault, 
			ViewpointDefaultValue, Datatype, Hidden, BegPos, EndPos)
		values(@Template, 'SubDetail', 1, 'PMSL', 'RecordType', 'Record Type', 'Y', 1, 'N', null, null, 'N', 1, 2)

		insert bPMUD(Template, RecordType, Seq, Form, ColumnName, ColDesc, Required, RecColumn, ViewpointDefault, ViewpointDefaultValue, Datatype, Hidden)
		values(@Template, 'SubDetail', 2, 'PMSL', 'ProjectCode', 'Project Code', 'N', 2, 'N', null, null, 'N')

		insert bPMUD(Template, RecordType, Seq, Form, ColumnName, ColDesc, Required, RecColumn, ViewpointDefault, 
			ViewpointDefaultValue, Datatype, Hidden, BegPos, EndPos)
		values(@Template, 'SubDetail', 3, 'PMSL', 'Item', 'Item', 'Y', 3, 'N', null, 'varchar(16)', 'N', 14, 24)

		insert bPMUD(Template, RecordType, Seq, Form, ColumnName, ColDesc, Required, RecColumn, ViewpointDefault, 
			ViewpointDefaultValue, Datatype, Hidden, BegPos, EndPos)
		values(@Template, 'SubDetail', 4, 'PMSL', 'Phase', 'Phase', 'Y', 4, 'N', null, 'bPhase', 'N', 25, 39)

		insert bPMUD(Template, RecordType, Seq, Form, ColumnName, ColDesc, Required, RecColumn, ViewpointDefault, 
			ViewpointDefaultValue, Datatype, Hidden, BegPos, EndPos)
		values(@Template, 'SubDetail', 5, 'PMSL', 'CostType', 'Cost Type', 'Y', 5, 'N', null, 'bJCCType', 'N', 40, 41)

		insert bPMUD(Template, RecordType, Seq, Form, ColumnName, ColDesc, Required, RecColumn, ViewpointDefault, 
			ViewpointDefaultValue, Datatype, Hidden, BegPos, EndPos)
		values(@Template, 'SubDetail', 6, 'PMSL', 'Units', 'Units', 'Y', 6, 'Y', 0, 'bUnits', 'N', 42, 56)

		insert bPMUD(Template, RecordType, Seq, Form, ColumnName, ColDesc, Required, RecColumn, ViewpointDefault, 
			ViewpointDefaultValue, Datatype, Hidden, BegPos, EndPos)
		values(@Template, 'SubDetail', 7, 'PMSL', 'UM', 'Unit of Measure', 'Y', 7, 'N', null, 'bUM', 'N', 57, 61)

		insert bPMUD(Template, RecordType, Seq, Form, ColumnName, ColDesc, Required, RecColumn, ViewpointDefault, 
			ViewpointDefaultValue, Datatype, Hidden, BegPos, EndPos)
		values(@Template, 'SubDetail', 8, 'PMSL', 'UnitCost', 'Unit Cost', 'Y', 8, 'Y', 0, 'bUnitCost', 'N', 62, 76)

		insert bPMUD(Template, RecordType, Seq, Form, ColumnName, ColDesc, Required, RecColumn, ViewpointDefault, ViewpointDefaultValue, Datatype, Hidden)
		values(@Template, 'SubDetail', 9, 'PMSL', 'WCRetgPct', 'WC Retainage %', 'Y', 9, 'Y', '**Upload Retainage %', 'bPct', 'N')

		insert bPMUD(Template, RecordType, Seq, Form, ColumnName, ColDesc, Required, RecColumn, ViewpointDefault, 
			ViewpointDefaultValue, Datatype, Hidden, BegPos, EndPos)
		values(@Template, 'SubDetail', 10, 'PMSL', 'Vendor', 'Vendor', 'Y', 10, 'N', null, 'bVendor', 'N', 77, 83)

		insert bPMUD(Template, RecordType, Seq, Form, ColumnName, ColDesc, Required, RecColumn, ViewpointDefault, ViewpointDefaultValue, Datatype, Hidden)
		values(@Template, 'SubDetail', 11, 'PMSL', 'Description', 'Description', 'Y', 11, 'N', null, 'bItemDesc', 'N')

		insert bPMUD(Template, RecordType, Seq, Form, ColumnName, ColDesc, Required, RecColumn, ViewpointDefault, ViewpointDefaultValue, Datatype, Hidden)
		values(@Template, 'SubDetail', 12, 'PMSL', 'Notes', 'Notes', 'Y', 12, 'N', null, 'varchar(max)', 'N')

		insert bPMUD(Template, RecordType, Seq, Form, ColumnName, ColDesc, Required, RecColumn, ViewpointDefault, ViewpointDefaultValue, Datatype, Hidden)
		values(@Template, 'SubDetail', 13, 'PMSL', 'Amount', 'Amount', 'N', 13, 'Y', '**Units x UnitCost', 'bDollar', 'N')

		insert bPMUD(Template, RecordType, Seq, Form, ColumnName, ColDesc, Required, RecColumn, ViewpointDefault, ViewpointDefaultValue, Datatype, Hidden)
		values(@Template, 'SubDetail', 14, 'PMSL', 'SMRetgPct', 'SM Retainage %', 'N', 14, 'Y', '**Upload Retainage %', 'bPct', 'N')

		insert bPMUD(Template, RecordType, Seq, Form, ColumnName, ColDesc, Required, RecColumn, ViewpointDefault, ViewpointDefaultValue, Datatype, Hidden)
		values(@Template, 'SubDetail', 15, 'PMSL', 'Supplier', 'Supplier', 'N', null, 'N', null, 'bVendor', 'N')

		insert bPMUD(Template, RecordType, Seq, Form, ColumnName, ColDesc, Required, RecColumn, ViewpointDefault, ViewpointDefaultValue, Datatype, Hidden)
		values(@Template, 'SubDetail', 16, 'PMSL', 'SendFlag', 'Send Flag', 'N', null, 'N', null, 'bYN', 'N')

		insert bPMUD(Template, RecordType, Seq, Form, ColumnName, ColDesc, Required, RecColumn, ViewpointDefault, ViewpointDefaultValue, Datatype, Hidden)
		values(@Template, 'SubDetail', 17, 'PMSL', 'TaxType', 'Tax Type', 'N', null, 'N', null, 'tinyint', 'N')

		insert bPMUD(Template, RecordType, Seq, Form, ColumnName, ColDesc, Required, RecColumn, ViewpointDefault, ViewpointDefaultValue, Datatype, Hidden)
		values(@Template, 'SubDetail', 18, 'PMSL', 'TaxCode', 'Tax Code', 'N', null, 'N', null, 'bTaxCode', 'N')

		insert bPMUD(Template, RecordType, Seq, Form, ColumnName, ColDesc, Required, RecColumn, ViewpointDefault, ViewpointDefaultValue, Datatype, Hidden)
		values(@Template, 'SubDetail', 19, 'PMSL', 'TaxGroup', 'Tax Group', 'N', null, 'N', null, 'bGroup', 'N')		
	end

	--Insert Material Detail Records into bPMUD--
	if not exists(select top 1 1 from PMUD with (nolock) where Template=@Template and RecordType='MatlDetail')
	begin
		insert bPMUD(Template, RecordType, Seq, Form, ColumnName, ColDesc, Required, RecColumn, ViewpointDefault, 
			ViewpointDefaultValue, Datatype, Hidden, BegPos, EndPos)
		values(@Template, 'MatlDetail', 1, 'PMMF', 'RecordType', 'Record Type', 'Y', 1, 'N', null, null, 'N', 1, 2)

		insert bPMUD(Template, RecordType, Seq, Form, ColumnName, ColDesc, Required, RecColumn, ViewpointDefault, ViewpointDefaultValue, Datatype, Hidden)
		values(@Template, 'MatlDetail', 2, 'PMMF', 'ProjectCode', 'Project Code', 'N', 2, 'N', null, null, 'N')

		insert bPMUD(Template, RecordType, Seq, Form, ColumnName, ColDesc, Required, RecColumn, ViewpointDefault, 
			ViewpointDefaultValue, Datatype, Hidden, BegPos, EndPos)
		values(@Template, 'MatlDetail', 3, 'PMMF', 'Item', 'Item', 'Y', 3, 'N', null, 'varchar(16)', 'N', 14, 24)

		insert bPMUD(Template, RecordType, Seq, Form, ColumnName, ColDesc, Required, RecColumn, ViewpointDefault, 
			ViewpointDefaultValue, Datatype, Hidden, BegPos, EndPos)
		values(@Template, 'MatlDetail', 4, 'PMMF', 'Phase', 'Phase', 'Y', 4, 'N', null, 'bPhase', 'N', 25, 39)

		insert bPMUD(Template, RecordType, Seq, Form, ColumnName, ColDesc, Required, RecColumn, ViewpointDefault, 
			ViewpointDefaultValue, Datatype, Hidden, BegPos, EndPos)
		values(@Template, 'MatlDetail', 5, 'PMMF', 'CostType', 'Cost Type', 'Y', 5, 'N', null, 'bJCCType', 'N', 40, 41)

		insert bPMUD(Template, RecordType, Seq, Form, ColumnName, ColDesc, Required, RecColumn, ViewpointDefault, 
			ViewpointDefaultValue, Datatype, Hidden, BegPos, EndPos)
		values(@Template, 'MatlDetail', 6, 'PMMF', 'Units', 'Units', 'Y', 6, 'Y', 0, 'bUnits', 'N', 42, 56)

		insert bPMUD(Template, RecordType, Seq, Form, ColumnName, ColDesc, Required, RecColumn, ViewpointDefault, 
			ViewpointDefaultValue, Datatype, Hidden, BegPos, EndPos)
		values(@Template, 'MatlDetail', 7, 'PMMF', 'UM', 'Unit of Measure', 'Y', 7, 'N', null, 'bUM', 'N', 57, 61)

		insert bPMUD(Template, RecordType, Seq, Form, ColumnName, ColDesc, Required, RecColumn, ViewpointDefault, 
			ViewpointDefaultValue, Datatype, Hidden, BegPos, EndPos)
		values(@Template, 'MatlDetail', 8, 'PMMF', 'UnitCost', 'Unit Cost', 'Y', 8, 'Y', 0, 'bUnitCost', 'N', 62, 76)

		insert bPMUD(Template, RecordType, Seq, Form, ColumnName, ColDesc, Required, RecColumn, ViewpointDefault, ViewpointDefaultValue, Datatype, Hidden)
		values(@Template, 'MatlDetail', 9, 'PMMF', 'ECM', 'ECM', 'Y', 9, 'Y', 'E', 'bECM', 'N')

		insert bPMUD(Template, RecordType, Seq, Form, ColumnName, ColDesc, Required, RecColumn, ViewpointDefault, 
			ViewpointDefaultValue, Datatype, Hidden, BegPos, EndPos)
		values(@Template, 'MatlDetail', 10, 'PMMF', 'Material', 'Material', 'Y', 10, 'N', null, 'bMatl', 'N', 77, 83)

		insert bPMUD(Template, RecordType, Seq, Form, ColumnName, ColDesc, Required, RecColumn, ViewpointDefault, 
			ViewpointDefaultValue, Datatype, Hidden, BegPos, EndPos)
		values(@Template, 'MatlDetail', 11, 'PMMF', 'Vendor', 'Vendor', 'Y', 11, 'N', null, 'bVendor', 'N', 84, 90)

		insert bPMUD(Template, RecordType, Seq, Form, ColumnName, ColDesc, Required, RecColumn, ViewpointDefault, 
			ViewpointDefaultValue, Datatype, Hidden, BegPos, EndPos)
		values(@Template, 'MatlDetail', 12, 'PMMF', 'MatlDescription', 'Description', 'Y', 12, 'N', null, 'bItemDesc', 'N', 91, 151)

		insert bPMUD(Template, RecordType, Seq, Form, ColumnName, ColDesc, Required, RecColumn, ViewpointDefault, ViewpointDefaultValue, Datatype, Hidden)
		values(@Template, 'MatlDetail', 13, 'PMMF', 'Notes', 'Notes', 'Y', 13, 'N', null, 'varchar(max)', 'N')

		insert bPMUD(Template, RecordType, Seq, Form, ColumnName, ColDesc, Required, RecColumn, ViewpointDefault, ViewpointDefaultValue, Datatype, Hidden)
		values(@Template, 'MatlDetail', 14, 'PMMF', 'MatlOption', 'Material Option', 'N', null, 'N', null, 'char(1)', 'N')

		insert bPMUD(Template, RecordType, Seq, Form, ColumnName, ColDesc, Required, RecColumn, ViewpointDefault, ViewpointDefaultValue, Datatype, Hidden)
		values(@Template, 'MatlDetail', 15, 'PMMF', 'RecvYN', 'Recieved YN', 'N', null, 'N', null, 'bYN', 'N')

		insert bPMUD(Template, RecordType, Seq, Form, ColumnName, ColDesc, Required, RecColumn, ViewpointDefault, ViewpointDefaultValue, Datatype, Hidden)
		values(@Template, 'MatlDetail', 16, 'PMMF', 'Location', 'Location', 'N', null, 'N', null, 'bLoc', 'N')

		insert bPMUD(Template, RecordType, Seq, Form, ColumnName, ColDesc, Required, RecColumn, ViewpointDefault, ViewpointDefaultValue, Datatype, Hidden)
		values(@Template, 'MatlDetail', 17, 'PMMF', 'Amount', 'Amount', 'N', 14, 'Y', '**Units x UnitCost', 'bDollar', 'N')

		insert bPMUD(Template, RecordType, Seq, Form, ColumnName, ColDesc, Required, RecColumn, ViewpointDefault, ViewpointDefaultValue, Datatype, Hidden)
		values(@Template, 'MatlDetail', 18, 'PMMF', 'TaxGroup', 'Tax Group', 'N', null, 'N', null, 'bGroup', 'N')

		insert bPMUD(Template, RecordType, Seq, Form, ColumnName, ColDesc, Required, RecColumn, ViewpointDefault, ViewpointDefaultValue, Datatype, Hidden)
		values(@Template, 'MatlDetail', 19, 'PMMF', 'TaxCode', 'Tax Code', 'N', null, 'N', null, 'bTaxCode', 'N')

		insert bPMUD(Template, RecordType, Seq, Form, ColumnName, ColDesc, Required, RecColumn, ViewpointDefault, ViewpointDefaultValue, Datatype, Hidden)
		values(@Template, 'MatlDetail', 20, 'PMMF', 'TaxType', 'Tax Type', 'N', null, 'N', null, 'tinyint', 'N')

		insert bPMUD(Template, RecordType, Seq, Form, ColumnName, ColDesc, Required, RecColumn, ViewpointDefault, ViewpointDefaultValue, Datatype, Hidden)
		values(@Template, 'MatlDetail', 21, 'PMMF', 'SendFlag', 'Send Flag', 'N', null, 'N', null, 'bYN', 'N')

		insert bPMUD(Template, RecordType, Seq, Form, ColumnName, ColDesc, Required, RecColumn, ViewpointDefault, ViewpointDefaultValue, Datatype, Hidden)
		values(@Template, 'MatlDetail', 22, 'PMMF', 'MSCo', 'MSCo', 'N', null, 'N', null, 'bCompany', 'N')

		insert bPMUD(Template, RecordType, Seq, Form, ColumnName, ColDesc, Required, RecColumn, ViewpointDefault, ViewpointDefaultValue, Datatype, Hidden)
		values(@Template, 'MatlDetail', 23, 'PMMF', 'Quote', 'Quote', 'N', null, 'N', null, 'varchar(10)', 'N')

		insert bPMUD(Template, RecordType, Seq, Form, ColumnName, ColDesc, Required, RecColumn, ViewpointDefault, ViewpointDefaultValue, Datatype, Hidden)
		values(@Template, 'MatlDetail', 24, 'PMMF', 'INCo', 'INCo', 'N', null, 'N', null, 'bCompany', 'N')

		insert bPMUD(Template, RecordType, Seq, Form, ColumnName, ColDesc, Required, RecColumn, ViewpointDefault, ViewpointDefaultValue, Datatype, Hidden)
		values(@Template, 'MatlDetail', 25, 'PMMF', 'Supplier', 'Supplier', 'N', null, 'N', null, 'bVendor', 'N')
	end

	--Insert Estimate Info Records into bPMUD--
	if not exists(select top 1 1 from PMUD with (nolock) where Template=@Template and RecordType='Estimate')
	begin
		insert bPMUD(Template, RecordType, Seq, Form, ColumnName, ColDesc, Required, RecColumn, ViewpointDefault, 
			ViewpointDefaultValue, Datatype, Hidden, BegPos, EndPos)
		values(@Template, 'Estimate', 1, 'JCCH', 'RecordType', 'Record Type', 'Y', 1, 'N', null, null, 'N', 1, 2)

		insert bPMUD(Template, RecordType, Seq, Form, ColumnName, ColDesc, Required, RecColumn, ViewpointDefault, 
			ViewpointDefaultValue, Datatype, Hidden, BegPos, EndPos)
		values(@Template, 'Estimate', 2, 'JCCH', 'ProjectCode', 'Project Code', 'N', 2, 'N', null, null, 'N', 3, 13)

		insert bPMUD(Template, RecordType, Seq, Form, ColumnName, ColDesc, Required, RecColumn, ViewpointDefault, 
			ViewpointDefaultValue, Datatype, Hidden, BegPos, EndPos)
		values(@Template, 'Estimate', 3, 'JCCH', 'Description', 'Description', 'Y', 3, 'N', null, 'bItemDesc', 'N', 13, 43)

		insert bPMUD(Template, RecordType, Seq, Form, ColumnName, ColDesc, Required, RecColumn, ViewpointDefault, 
			ViewpointDefaultValue, Datatype, Hidden, BegPos, EndPos)
		values(@Template, 'Estimate', 4, 'JCCH', 'JobPhone', 'Job Phone', 'Y', 4, 'N', null, 'bPhone', 'N', 42, 62)

		insert bPMUD(Template, RecordType, Seq, Form, ColumnName, ColDesc, Required, RecColumn, ViewpointDefault, 
			ViewpointDefaultValue, Datatype, Hidden, BegPos, EndPos)
		values(@Template, 'Estimate', 5, 'JCCH', 'JobFax', 'Job Fax', 'Y', 5, 'N', null, 'bPhone', 'N', 63, 83)

		insert bPMUD(Template, RecordType, Seq, Form, ColumnName, ColDesc, Required, RecColumn, ViewpointDefault, 
			ViewpointDefaultValue, Datatype, Hidden, BegPos, EndPos)
		values(@Template, 'Estimate', 6, 'JCCH', 'MailAddress', 'Mail Address 1', 'Y', 6, 'N', null, 'varchar(60)', 'N', 83, 143)

		insert bPMUD(Template, RecordType, Seq, Form, ColumnName, ColDesc, Required, RecColumn, ViewpointDefault, 
			ViewpointDefaultValue, Datatype, Hidden, BegPos, EndPos)
		values(@Template, 'Estimate', 7, 'JCCH', 'MailAddress2', 'Mail Address 2', 'Y', 7, 'N', null, 'varchar(60)', 'N', 143, 203)

		insert bPMUD(Template, RecordType, Seq, Form, ColumnName, ColDesc, Required, RecColumn, ViewpointDefault, 
			ViewpointDefaultValue, Datatype, Hidden, BegPos, EndPos)
		values(@Template, 'Estimate', 8, 'JCCH', 'MailCity', 'Mail City', 'Y', 8, 'N', null, 'varchar(30)', 'N', 203, 233)

		insert bPMUD(Template, RecordType, Seq, Form, ColumnName, ColDesc, Required, RecColumn, ViewpointDefault, 
			ViewpointDefaultValue, Datatype, Hidden, BegPos, EndPos)
		values(@Template, 'Estimate', 9, 'JCCH', 'MailState', 'Mail State', 'Y', 9, 'N', null, 'varchar(4)', 'N', 233, 235)

		insert bPMUD(Template, RecordType, Seq, Form, ColumnName, ColDesc, Required, RecColumn, ViewpointDefault, 
			ViewpointDefaultValue, Datatype, Hidden, BegPos, EndPos)
		values(@Template, 'Estimate', 10, 'JCCH', 'MailZip', 'Mail Zip Code', 'Y', 10, 'N', null, 'bZip', 'N', 235, 247)

		insert bPMUD(Template, RecordType, Seq, Form, ColumnName, ColDesc, Required, RecColumn, ViewpointDefault, 
			ViewpointDefaultValue, Datatype, Hidden, BegPos, EndPos)
		values(@Template, 'Estimate', 11, 'JCCH', 'ShipAddress', 'Ship Address 1', 'Y', 11, 'N', null, 'varchar(60)', 'N', 247, 307)

		insert bPMUD(Template, RecordType, Seq, Form, ColumnName, ColDesc, Required, RecColumn, ViewpointDefault, 
			ViewpointDefaultValue, Datatype, Hidden, BegPos, EndPos)
		values(@Template, 'Estimate', 12, 'JCCH', 'ShipAddress2', 'Ship Address 2', 'Y', 12, 'N', null, 'varchar(60)', 'N', 307, 367)

		insert bPMUD(Template, RecordType, Seq, Form, ColumnName, ColDesc, Required, RecColumn, ViewpointDefault, 
			ViewpointDefaultValue, Datatype, Hidden, BegPos, EndPos)
		values(@Template, 'Estimate', 13, 'JCCH', 'ShipCity', 'Ship City', 'Y', 13, 'N', null, 'varchar(30)', 'N', 367, 397)

		insert bPMUD(Template, RecordType, Seq, Form, ColumnName, ColDesc, Required, RecColumn, ViewpointDefault, 
			ViewpointDefaultValue, Datatype, Hidden, BegPos, EndPos)
		values(@Template, 'Estimate', 14, 'JCCH', 'ShipState', 'Ship State', 'Y', 14, 'N', null, 'varchar(4)', 'N', 397, 399)

		insert bPMUD(Template, RecordType, Seq, Form, ColumnName, ColDesc, Required, RecColumn, ViewpointDefault, 
			ViewpointDefaultValue, Datatype, Hidden, BegPos, EndPos)
		values(@Template, 'Estimate', 15, 'JCCH', 'ShipZip', 'Ship Zip Code', 'Y', 15, 'N', null, 'bZip', 'N', 399, 411)

		insert bPMUD(Template, RecordType, Seq, Form, ColumnName, ColDesc, Required, RecColumn, ViewpointDefault, ViewpointDefaultValue, Datatype, Hidden)
		values(@Template, 'Estimate', 16, 'JCCH', 'Notes', 'Notes', 'Y', 16, 'N', null, 'varchar(max)', 'N')
	end

	--Make Updates for Timberline Templates
	if @ImportRoutine = 'Timberline'
	begin
		--Only check Phase, CostType, and Estimate. Set Identifiers.
		update bPMUR
		set ContractItem = 'N', SubcontractDetail = 'N', MaterialDetail = 'N',
			ContractItemID = null, PhaseID = 'P', CostTypeID = 'C', SubcontractDetailID = null, 
			MaterialDetailID = null, EstimateInfoID = '*'
		where Template = @Template

		--Clear RecColumn for Phase, CostType, and Estimate
		update bPMUD
		set RecColumn = null
		where Template = @Template and RecordType in ('Phase','CostType','Estimate')

		--Insert new Timberline only records
		insert bPMUD(Template, RecordType, Seq, Form, ColumnName, ColDesc, Required, RecColumn, Hidden)
		values(@Template, 'Phase', 10, 'JCJP', 'Misc1', 'Timberline Misc1', 'N', 4, 'N')

		insert bPMUD(Template, RecordType, Seq, Form, ColumnName, ColDesc, Required, RecColumn, Hidden)
		values(@Template, 'Phase', 11, 'JCJP', 'Misc2', 'Timberline Misc2', 'N', 5, 'N')

		insert bPMUD(Template, RecordType, Seq, Form, ColumnName, ColDesc, Required, RecColumn, Hidden)
		values(@Template, 'Phase', 12, 'JCJP', 'Quantity', 'Timberline Quantity', 'N', 6, 'N')

		insert bPMUD(Template, RecordType, Seq, Form, ColumnName, ColDesc, Required, RecColumn, Hidden)
		values(@Template, 'Phase', 13, 'JCJP', 'UM', 'Timberline UM', 'N', 7, 'N')

		insert bPMUD(Template, RecordType, Seq, Form, ColumnName, ColDesc, Required, RecColumn, Hidden)
		values(@Template, 'CostType', 16, 'JCCH', 'Misc1', 'Timberline Misc1', 'N', 3, 'N')

		insert bPMUD(Template, RecordType, Seq, Form, ColumnName, ColDesc, Required, RecColumn, Hidden)
		values(@Template, 'CostType', 17, 'JCCH', 'Misc2', 'Timberline Misc2', 'N', 5, 'N')

		--Update RecColumn values
		update bPMUD
		set RecColumn = 1
		where Template = @Template and RecordType = 'Phase' and ColumnName = 'RecordType'

		update bPMUD
		set RecColumn = 2
		where Template = @Template and RecordType = 'Phase' and ColumnName = 'Phase'

		update bPMUD
		set RecColumn = 3
		where Template = @Template and RecordType = 'Phase' and ColumnName = 'Description'

		update bPMUD
		set RecColumn = 1
		where Template = @Template and RecordType = 'CostType' and ColumnName = 'RecordType'

		update bPMUD
		set RecColumn = 2
		where Template = @Template and RecordType = 'CostType' and ColumnName = 'Phase'

		update bPMUD
		set RecColumn = 4
		where Template = @Template and RecordType = 'CostType' and ColumnName = 'CostType'

		update bPMUD
		set RecColumn = 6
		where Template = @Template and RecordType = 'CostType' and ColumnName = 'Units'

		update bPMUD
		set RecColumn = 7
		where Template = @Template and RecordType = 'CostType' and ColumnName = 'UM'

		update bPMUD
		set RecColumn = 8
		where Template = @Template and RecordType = 'CostType' and ColumnName = 'Costs'

		update bPMUD
		set RecColumn = 1
		where Template = @Template and RecordType = 'Estimate' and ColumnName = 'RecordType'

		update bPMUD
		set RecColumn = 2
		where Template = @Template and RecordType = 'Estimate' and ColumnName = 'ProjectCode'

		update bPMUD
		set RecColumn = 3
		where Template = @Template and RecordType = 'Estimate' and ColumnName = 'Description'

		update bPMUD
		set RecColumn = 4
		where Template = @Template and RecordType = 'Estimate' and ColumnName = 'MailAddress'

		update bPMUD
		set RecColumn = 5
		where Template = @Template and RecordType = 'Estimate' and ColumnName = 'MailCity'

		update bPMUD
		set RecColumn = 6
		where Template = @Template and RecordType = 'Estimate' and ColumnName = 'MailState'

		update bPMUD
		set RecColumn = 7
		where Template = @Template and RecordType = 'Estimate' and ColumnName = 'MailZip'

		update bPMUD
		set RecColumn = 8
		where Template = @Template and RecordType = 'Estimate' and ColumnName = 'ShipAddress'

		update bPMUD
		set RecColumn = 9
		where Template = @Template and RecordType = 'Estimate' and ColumnName = 'ShipAddress2'

		update bPMUD
		set RecColumn = 10
		where Template = @Template and RecordType = 'Estimate' and ColumnName = 'ShipCity'

		update bPMUD
		set RecColumn = 11
		where Template = @Template and RecordType = 'Estimate' and ColumnName = 'ShipState'
		
		update bPMUD
		set RecColumn = 12
		where Template = @Template and RecordType = 'Estimate' and ColumnName = 'ShipZip'
	end

	commit transaction
end try

begin catch
	select @msg = 'Error: ' + error_message() + char(13) + char(10) + 'Line #' + cast(error_line() as nvarchar(3)), @rcode = 1
	rollback transaction
end catch


vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMImportPMUDDefault] TO [public]
GO
