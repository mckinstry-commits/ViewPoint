SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE      proc [dbo].[vspEMACProcess]
/*************************************
* CREATED BY: AE   4/16/99
* Re-Write BY TerryLis 12/18/07 for VP6.1 Issue 120566
* MODIFIED By: DAN SO - 05/08/08 - Issue: 128084 - Default UM 'LS' when inserting into bEMBF
*				TRL Issue 129249 07/31/08 Fixed error converting EMEM ud field for Alloc amt/rate
*				TRL Issue 131067 01/12/08 Fixed negative rounding issue when/if alloc is ran twice
*				TRL Issue 134913 added "and @EMAHamtrateflag<>'C'"
*				TRL Issue 136527  added rounding code distribution code
*				AMR 01/17/11 - #142350, making case insensitive by removing unused vars and renaming same named variables-  
*				GF 08/23/2012 TK-17328 check allocated vs basis rounding problem for variable 'ud' only with basis column
*				GF 03/18/2013 TFS-44145 148251 error in rounding correction for ud column that is amount and basis
*
* USAGE:
 * used by EMACRUN to process an allocation
 *
 * Pass in :
 *	EMCo, Mth, BatchId, AllocationCode, AllocationDate, Equip, Dept, Categ, Amt, Rate
 *      BeginDate, EndDate, GetBasis, Reversal, Basis
 *
 * NOTE:  If MthDateFlag is M then Begin and End Date are not used
 *
 * Returns
 *	BasisAmount, Error message and return code
 *
 * Error returns no rows
*******************************/
(@emco bCompany, 
@mth bMonth, 
@batchid bBatchID, 
@alloccode smallint, 
@actualdate bDate,
@equipment bEquip, 
@department bDept, 
@category varchar(10), 
@allocamt bDollar, 
@allocrate bRate, 
@begindate bDate, 
@enddate bDate,
@reversal tinyint =0,
@getbasis tinyint=0,
@basis bDollar output, 
@errmsg varchar(255) = null output)

as

set nocount on
    
declare @rcode int, 
/*HQ Group info*/
@matlgroup bGroup,
@emgroup bGroup,
/*EMAH Allocation info*/
@EMAHselectcategory varchar(1), 
@EMAHselectdepartment varchar(1), 
@EMAHselectequipment varchar(1),
@EMAHallocbasis varchar(1),
@EMAHamtrateflag varchar(1), 
@EMAHbasiscolumn varchar(30),
@EMAHamtcolumn varchar(30), 
@EMAHratecolumn varchar(30), 
@EMAHmthdateflag varchar(1), 
@EMAHcostcode bCostCode, 
@EMAHcosttype bEMCType, 
@EMAHdebitacct bGLAcct, 
@EMAHcreditacct bGLAcct,
@EMAHglco bCompany, 
/*Cost allocation variables*/
@AllocType int,  
@CCode bCostCode, 
@CType bEMCType, 
/*Used for select string for cursor, 
converts @emco parameter to string*/
@VEMCo varchar(3),
/*Return amt from cursor select statements 
for 'V' Allocation typs*/
@variablebasis numeric(12, 2),
--#142350 - renaming @Equipment
@Equip bEquip, 

/*Used all through procedure*/
@alloctotal bDollar, 
@BasisInsert numeric(12, 2), 
@batchseq int,
--#142350 - renaming @Department
@Dept bDept,
@Description bDesc, 
@EMCoInsert bCompany, 
@EquipInsert bEquip, 
@numrows int, 

@opencursor tinyint,  
@addemco bCompany, 
@addequip bJob, 
@addallocamt bDollar,

@status tinyint,
@TestEquip bEquip,
@Type char(1),
@CompOfEquip bEquip,
@ComponentTypeCode varchar(10),
@Component bEquip,

@opencursor2 tinyint,
@costemco bCompany,
@costequip bJob,
@costccode bCostCode,
@costctype bEMCType,
@costBasisInsert numeric(12, 2),
@sql varchar(100),

@alloctoadjust bDollar,
----TK-17328 TFS-44145
@SavedAllocAmt bDollar
SET @SavedAllocAmt = ISNULL(@basis,0)
   

 
create table #EquipTable (EMCo tinyint not null,
	Equip varchar(20) not null,
    Basis numeric(12, 2) not null,
    AllocAmt numeric(12, 2) not null,
    AllocRate numeric(8, 6) null,
    Dept varchar(10),--not null, TV 07/12/2005 - issue 29254 - Allow Deptartment to be Null.
    Categ varchar(10),
	EMGroup tinyint not null)--not null)
    
CREATE UNIQUE INDEX bitmpProjInit ON #EquipTable (EMCo, Equip)

create table #BaseTable (EMCo tinyint not null,
	Equip varchar(20) not null,
	RevCode varchar(10) null,
	Basis numeric(12, 2) not null,
	EMGroup tinyint not null)
    
create table #CostTable (EMCo tinyint not null,
	Equipment varchar(20) not null,
   	CCode varchar(10) not null,
   	CType tinyint not null,
   	BasisInsert numeric(12, 2) not null)
    
select @VEMCo = convert(varchar(3),@emco),  @alloctoadjust = 0, @rcode = 0

/* Get MatlGroup, EMGroup*/
select @matlgroup = MatlGroup , @emgroup = EMGroup from dbo.HQCO with (nolock) where HQCo = @emco
  
/* Validate Batch info */
exec @rcode = bspHQBatchProcessVal @emco, @mth, @batchid, 'EMAlloc', 'EMBF', @errmsg output, @status output
    
if @rcode <> 0
begin
	select '@errmsg= ' + isnull(convert(varchar(20),@errmsg),'')
    select @errmsg = @errmsg, @rcode = 1
    goto vspexit
end

if @status <> 0
begin
	select @errmsg = 'Invalid Batch status!', @rcode = 1
	goto vspexit
end

/*Start by getting information about the allocation code */
select @EMAHselectequipment=SelectEquip, @EMAHselectdepartment=SelectDept, @EMAHselectcategory = SelectCatgy,
	@EMAHallocbasis=AllocBasis, @EMAHamtrateflag=AmtRateFlag, @EMAHbasiscolumn = BasisCol,
    @EMAHamtcolumn=EquipAmtCol, @EMAHratecolumn=EquipRateCol, @EMAHmthdateflag=MthDateFlag,
    @EMAHcostcode=CostCode, @EMAHcosttype=CostType, @EMAHglco=GLCo,
    @EMAHdebitacct=GLDebitAcct, @EMAHcreditacct=GLCreditAcct, @Description=Description
from dbo.EMAH with (nolock)
where EMCo=@emco and AllocCode=@alloccode
if @@rowcount <> 1
begin
	select @errmsg = 'Invalid Allocation code!', @rcode = 1
	goto vspexit
end

if @EMAHamtcolumn is null and @allocamt is null and @EMAHamtrateflag = 'A' and @EMAHallocbasis <> 'V'
begin
	select @errmsg = 'Missing allocation amount or equipment column, cannot create!', @rcode = 1
	goto vspexit
end

if @EMAHratecolumn is null and @allocrate is null and @EMAHamtrateflag = 'R' and @EMAHallocbasis <> 'V'
begin
	select @errmsg = 'Missing allocation rate or equipment column, cannot create!', @rcode = 1
	goto vspexit
end

--Retrieve Equipment to allocations
/* Cannot be Inactive since this is validated at form level  - Issue 16224 */
If @EMAHselectequipment ='E' and @EMAHselectdepartment ='D' and @EMAHselectcategory ='C'
begin
	insert into #EquipTable(EMCo, Equip, Basis, AllocAmt, Dept, Categ, EMGroup)
	select EMEM.EMCo,EMEM.Equipment,0,0,EMEM.Department,EMEM.Category, @emgroup
	From dbo.EMEM  with(nolock)
	Where EMEM.EMCo=@emco and EMEM.Status <> 'I' 
	and	EMEM.Equipment IN (select Equipment from dbo.EMAE with (nolock) where EMCo=@emco and AllocCode = @alloccode)
	and	EMEM.Department IN(select Department from dbo.EMAD with (nolock) where EMCo=@emco and AllocCode = @alloccode)
	and	EMEM.Category IN (select Category from dbo.EMAG with (nolock) where EMCo=@emco and AllocCode = @alloccode)
end

If @EMAHselectequipment ='E' and @EMAHselectdepartment ='D' and @EMAHselectcategory <>'C'
begin
	insert into #EquipTable(EMCo, Equip, Basis, AllocAmt, Dept, Categ, EMGroup)
	select EMEM.EMCo,EMEM.Equipment,0,0,EMEM.Department,EMEM.Category, @emgroup
	From dbo.EMEM  with(nolock)
	Where EMEM.EMCo=@emco and EMEM.Status <> 'I' 
	and	EMEM.Equipment IN(select Equipment from dbo.EMAE with (nolock) where EMCo=@emco and AllocCode = @alloccode)
	and	EMEM.Department IN (select Department from dbo.EMAD with (nolock) where EMCo=@emco and AllocCode = @alloccode)
	and	EMEM.Category = case  @EMAHselectcategory when  'A' then EMEM.Category
												  when  'P' then @category end 	
end

If @EMAHselectequipment ='E' and @EMAHselectdepartment <>'D' and @EMAHselectcategory ='C'
begin
	insert into #EquipTable(EMCo, Equip, Basis, AllocAmt, Dept, Categ, EMGroup)
	select EMEM.EMCo,EMEM.Equipment,0,0,EMEM.Department,EMEM.Category, @emgroup
	From dbo.EMEM  with(nolock)
	Where EMEM.EMCo=@emco and EMEM.Status <> 'I' 
	and	EMEM.Equipment IN (select Equipment from dbo.EMAE with (nolock) where EMCo=@emco and AllocCode = @alloccode)
	and	EMEM.Department = case  @EMAHselectdepartment when 'A' then EMEM.Department
													  when  'P' then @department end
	and	EMEM.Category IN(select Category from dbo.EMAG with (nolock) where EMCo=@emco and AllocCode = @alloccode)
end

If @EMAHselectequipment ='E' and @EMAHselectdepartment <>'D' and @EMAHselectcategory <>'C'
begin
	insert into #EquipTable(EMCo, Equip, Basis, AllocAmt, Dept, Categ, EMGroup)
	select EMEM.EMCo,EMEM.Equipment,0,0,EMEM.Department,EMEM.Category, @emgroup
	From dbo.EMEM  with(nolock)
	Where EMEM.EMCo=@emco and EMEM.Status <> 'I' 
	and	EMEM.Equipment IN (select Equipment from dbo.EMAE with (nolock) where EMCo=@emco and AllocCode = @alloccode)
	and	EMEM.Department = case  @EMAHselectdepartment when 'A' then EMEM.Department
													  when  'P' then @department end
	and	EMEM.Category = case  @EMAHselectcategory when  'A' then EMEM.Category
												  when  'P' then @category end 	
end

If @EMAHselectequipment <>'E' and @EMAHselectdepartment ='D' and @EMAHselectcategory <>'C'
begin
	insert into #EquipTable(EMCo, Equip, Basis, AllocAmt, Dept, Categ, EMGroup)
	select EMEM.EMCo,EMEM.Equipment,0,0,EMEM.Department,EMEM.Category, @emgroup
	From dbo.EMEM  with(nolock)
	Where EMEM.EMCo=@emco and EMEM.Status <> 'I' 
	and	EMEM.Equipment = case @EMAHselectequipment when  'A' then EMEM.Equipment
												  when  'P' then  @equipment end
	and	EMEM.Department IN (select Department from dbo.EMAD with (nolock) where EMCo=@emco and AllocCode = @alloccode)					  
	and	EMEM.Category = case  @EMAHselectcategory when  'A' then EMEM.Category
												  when  'P' then @category end 	
end

If @EMAHselectequipment <>'E' and @EMAHselectdepartment ='D' and @EMAHselectcategory ='C'
begin
	insert into #EquipTable(EMCo, Equip, Basis, AllocAmt, Dept, Categ, EMGroup)
	select EMEM.EMCo,EMEM.Equipment,0,0,EMEM.Department,EMEM.Category, @emgroup
	From dbo.EMEM  with(nolock)
	Where EMEM.EMCo=@emco and EMEM.Status <> 'I' 
	and	EMEM.Equipment = case @EMAHselectequipment when  'A' then EMEM.Equipment
								 				  when  'P' then  @equipment end
	and	EMEM.Department IN (select Department from dbo.EMAD with (nolock) where EMCo=@emco and AllocCode = @alloccode)					  
	and	EMEM.Category IN (select Category from dbo.EMAG with (nolock) where EMCo=@emco and AllocCode = @alloccode)
end

If @EMAHselectequipment <>'E' and @EMAHselectdepartment <>'D' and @EMAHselectcategory ='C'
begin
	insert into #EquipTable(EMCo, Equip, Basis, AllocAmt, Dept, Categ, EMGroup)
	select EMEM.EMCo,EMEM.Equipment,0,0,EMEM.Department,EMEM.Category, @emgroup
	From dbo.EMEM with(nolock)
	Where EMEM.EMCo=@emco and EMEM.Status <> 'I' 
	and	EMEM.Equipment = case @EMAHselectequipment when  'A' then EMEM.Equipment
								 				  when  'P' then  @equipment end
	and	EMEM.Department = case  @EMAHselectdepartment when 'A' then EMEM.Department
					  								  when  'P' then @department end
	and	EMEM.Category In(select Category from dbo.EMAG with (nolock) where EMCo=@emco and AllocCode = @alloccode)
end

If @EMAHselectequipment <>'E' and @EMAHselectdepartment <>'D' and @EMAHselectcategory <>'C'
begin
	insert into #EquipTable(EMCo, Equip, Basis, AllocAmt, Dept, Categ, EMGroup)
	select EMEM.EMCo,EMEM.Equipment,0,0,EMEM.Department,EMEM.Category, @emgroup
	From dbo.EMEM with(nolock)
	Where EMEM.EMCo=@emco and EMEM.Status <> 'I' 
		and	EMEM.Equipment = case @EMAHselectequipment when  'A' then EMEM.Equipment
								 				  when  'P' then  @equipment end
	and	EMEM.Department = case  @EMAHselectdepartment when 'A' then EMEM.Department
					  								  when  'P' then @department end
	and	EMEM.Category = case  @EMAHselectcategory when  'A' then EMEM.Category
												  when  'P' then @category end
end
--Exit Procedure if no equipment has been selected
select @numrows = count(*) from #EquipTable
if @numrows=0
begin
   	select @errmsg = 'No Equipment selected for allocation!', @rcode=1
	goto vspexit
end

------------------------------------------------------------------------
/* Calculate the basis amounts */
----select '@EMAHallocbasis= ' + isnull(convert(varchar(20),@EMAHallocbasis),'')
if @EMAHallocbasis = 'R' or @EMAHallocbasis = 'H' or @EMAHallocbasis = 'V'
BEGIN
	--1. Varaible Allocations
	if @EMAHallocbasis = 'V'
	begin
		--1.  Cycle through temp table #EquipTable through while statement
		--	  Can't include temp table in cursor, update statement 
		--2.  get amount from specified field in EMAH (EM Allocations)
		--3.  Create cursor to get amount for equipment and update information into the base table
		--4.  Add record to #BaseTable tht holds Revenue Code and basis mount
		select @Equip = min(Equip) from #EquipTable
    	while IsNull(@Equip,'') <> ''
    	begin
			select @variablebasis = 0
    		--select '@Equip= ' + @Equip --convert(varchar(20),@Equip)
    		if IsNull(@EMAHbasiscolumn,'') <> ''
    		begin
    			--Creating Cursor
    			declare @strcursor varchar(500)
    			select @strcursor = 'declare EM_cursor cursor global for select ' + isnull(@EMAHbasiscolumn,'') + ' from dbo.EMEM with(nolock) where EMCo = ' + isnull(@VEMCo,'') + ' and Equipment = '''+ isnull(@Equip,'') + ''''
    			--run cursor
    			exec (@strcursor)
    			open EM_cursor
    			fetch next from EM_cursor into @variablebasis
    			--@variablebasis amount from specified in EMEM
    			close EM_cursor
    			deallocate EM_cursor
    		end 
    		if IsNull(@Equip,'')<> '' and IsNull(@variablebasis,0) <> 0
			begin
				--Update Base table only if amount field is greater than zero
    			insert into #BaseTable(EMCo, Equip, RevCode, Basis, EMGroup) 
				select @emco, @Equip, 0, @variablebasis, @emgroup
			end
    		select @Equip = min(Equip) from #EquipTable where Equip > @Equip
    	end --while @Equip is not null
    	goto joinit
    end -- if @allocbasis = 'V'
    
	--All allocations, either by Month or Date Range	
	If @EMAHmthdateflag = 'M'
		begin
			--By Month
			insert into #BaseTable(EMCo, Equip, RevCode, Basis, EMGroup) 
    			select d.EMCo, d.Equipment, d.RevCode,
			'Basis'= CASE @EMAHallocbasis WHEN 'R' THEN sum(d.Dollars)
					                  WHEN 'H' THEN sum(d.TimeUnits) END,
			@emgroup
	    	from dbo.EMRD d with (nolock) 
			join #EquipTable t on d.EMCo=t.EMCo and d.Equipment=t.Equip and d.EMGroup=t.EMGroup
			join dbo.EMAV v with(nolock) on v.EMCo=d.EMCo and v.EMGroup=d.EMGroup and v.RevCode=d.RevCode
			--where d.RevCode in (select RevCode from dbo.EMAV c with (nolock) where c.EMCo=@emco and c.AllocCode=@alloccode and c.EMGroup=@emgroup)
			--and d.Mth=@mth
			--group by d.EMCo, d.Equipment, d.RevCode
			where  d.EMCo=@emco and d.EMGroup=@emgroup and v.AllocCode = @alloccode and d.Mth=@mth
			group by d.EMCo,d.Equipment,d.RevCode
		end
	else
		begin
			--By Date Range
			insert into #BaseTable(EMCo, Equip, RevCode, Basis, EMGroup)
			select d.EMCo, d.Equipment, d.RevCode,
			'Basis'= case @EMAHallocbasis WHEN 'R' THEN sum(d.Dollars)
									  WHEN 'H' THEN sum(d.TimeUnits) END,
			@emgroup
			from dbo.EMRD d with (nolock) 
			join #EquipTable t on d.EMCo=t.EMCo and d.Equipment=t.Equip and d.EMGroup=t.EMGroup
			join dbo.EMAV v with(nolock) on v.EMCo=d.EMCo and v.EMGroup=d.EMGroup and  v.RevCode=d.RevCode
			--where d.RevCode in (select RevCode from dbo.EMAV c with (nolock) where c.EMCo=@emco and c.AllocCode=@alloccode and c.EMGroup=@emgroup)
			where d.EMCo=@emco and d.EMGroup=@emgroup and v.AllocCode = @alloccode and d.ActualDate >= @begindate and d.ActualDate <=@enddate 
			group by d.EMCo, d.Equipment, d.RevCode
		end
	
	--Hourly Allocations up Revenue Codes	
 	if @EMAHallocbasis = 'H'
	begin
	   	update #BaseTable Set Basis = (x.Basis * y.HrsPerTimeUM) 
		from #BaseTable x
		Inner Join dbo.EMRC y with(nolock)on x.EMGroup=y.EMGroup and x.RevCode=y.RevCode
	end
    
	joinit:
    select @TestEquip = min(Equip) from #BaseTable
    while @TestEquip is not null
    begin
		--Get basis amount from #BaseTable
		select @basis = sum(Basis) 
		from #BaseTable j 
		where j.EMCo = @emco and j.Equip = @TestEquip
		--Update basis in #EquipTable from Base Table
    	update #EquipTable 
		Set Basis=@basis 
		from #EquipTable t, #BaseTable b 
		where b.EMCo=t.EMCo and b.Equip=t.Equip and t.Equip = @TestEquip
    	
		select @TestEquip = min(Equip) from #BaseTable where Equip > @TestEquip
    end --while @TestEquip is not null
    ----------------------------------------------------------
	--Override Allocation rate from EMACProcess form 
	--if amount exists in EMEM
	--Issue 129249 fix
    if IsNull(@EMAHratecolumn,'') <> ''
    begin
		select @Equip = min(Equip) from #EquipTable
    	while @Equip is not null
    	begin
    		select @Equip =  + isnull(convert(varchar(20),@Equip),'')
    		exec('declare EM_cursor cursor global for select ' + @EMAHratecolumn + ' from dbo.EMEM with(nolock) where EMCo = ' + @VEMCo + ' and Equipment = ''' + @Equip + '''')
    		open EM_cursor
    		fetch next from EM_cursor into @allocrate
    		close EM_cursor
    		deallocate EM_cursor

    		update #EquipTable 
			Set AllocRate = isnull(@allocrate,0) 
			from #EquipTable 
			where EMCo = @emco and Equip = @Equip

    		select @Equip = min(Equip) from #EquipTable where Equip > @Equip

    	end --while @Equip is not null
    end -- if @EMAHratecolumn is not null
    ---------------------------------------------------------------------
	--Override Allocation amount from EMACProcess form 
	--if amount exists in EMEM
	--Issue 129249 fix
    if IsNull(@EMAHamtcolumn,'') <> ''
    begin
    	select @Equip = min(Equip) from #EquipTable
    	while @Equip is not null
    	begin
    		select @Equip=  + isnull(convert(varchar(20),@Equip),'')
    		exec('declare EM_cursor cursor global for select ' + @EMAHamtcolumn + ' from dbo.EMEM with(nolock) where EMCo = ' + @VEMCo + ' and Equipment = ''' + @Equip + '''')
    		open EM_cursor
    		fetch next from EM_cursor into @allocamt
    		close EM_cursor
    		deallocate EM_cursor
    		
			if IsNull(@allocamt,0) <> 0
			begin
				update #EquipTable 
				Set AllocAmt = isnull(@allocamt,0) 
				from #EquipTable
				 where EMCo = @emco and Equip = @Equip
    		end

			select @Equip = min(Equip) from #EquipTable where Equip > @Equip
    	end --while @Equip is not null
    end --if @EMAHamtcolumn is not null
    
    select @basis = sum(Basis) from #EquipTable
    ----select '@basis = ' + isnull(convert(varchar(20),@basis),'')
    --drop table #BaseTable
    
    if @getbasis=1
    begin
		select @errmsg = 'Basis returned.', @rcode=0
    	goto vspexit
    end
    	
    if @basis = 0
    begin
		select @errmsg = 'Basis is 0, cannot create Allocations!', @rcode=1
    	goto vspexit
    end
    	
    /* once basis has been calculated then we can calculate the allocation based on Type */
    ----TK-17328
    if @EMAHamtrateflag = 'A' AND @EMAHallocbasis <> 'V'
	begin
		if IsNull(@allocamt,0)<> 0
		begin
			update #EquipTable
			set AllocAmt =(Basis / (select sum(Basis) from #EquipTable)) * @allocamt
		end
	end

	--if @EMAHamtrateflag='C'
	    --update #EquipTable set AllocAmt = (Basis / (select sum(Basis) from #EquipTable)) * AllocAmt

    if @EMAHamtrateflag = 'R' 
	begin 
		update #EquipTable 
		set AllocAmt = Basis * @allocrate 
	end
    if @EMAHamtrateflag = 'T'
	begin 
		update #EquipTable 
		set AllocAmt = Basis * isnull(AllocRate,0) 
	end

/* now each row in #EquipTable should coorespond to a Batch Entry */
donecalculating:
	/*Issue 131076
	if we're allocating an amount, and not using a column in JCJM check and
	make sure that we allocated the full amount
	if there is a rounding descrepency we add it to the last item
	If amount remaining to allocate, adjust last batch seq with difference. for non-user memo amounts only*/
	--134913 added "and @EMAHamtrateflag<>'C'"
	
	
---- TK-17328 rounding problem for basis column @EMAHbasiscolumn when variable basis
IF ISNULL(@EMAHbasiscolumn, '') <> '' AND @EMAHallocbasis = 'V' ----AND SUBSTRING(@EMAHbasiscolumn,1,2) = 'ud'
	BEGIN
	SET @alloctoadjust = 0
	----TFS-44145
	IF @SavedAllocAmt = 0
		BEGIN
		SELECT @SavedAllocAmt = SUM(ISNULL(Basis,0)) FROM #EquipTable
		IF @SavedAllocAmt = 0
			BEGIN
			SELECT @SavedAllocAmt = SUM(ISNULL(AllocAmt,0)) FROM #EquipTable   
			END	
		END
		  
	select @alloctoadjust = @SavedAllocAmt - sum(AllocAmt) from #EquipTable


	if @alloctoadjust <> 0 
		BEGIN
		update Top (1) #EquipTable
		set AllocAmt = IsNull(AllocAmt,0) + @alloctoadjust
		WHERE ISNULL(AllocAmt,0) <> 0
		END
	END
ELSE
	BEGIN
	if @EMAHamtcolumn is not null  and @EMAHamtrateflag <> 'C'
		begin
		select @alloctoadjust = IsNull(@allocamt,0) - sum(Basis) from #EquipTable

		SELECT 'Alloc To Adjust: ' + dbo.vfToString(@alloctoadjust)

		if @alloctoadjust <> 0 
			begin
			update Top (1) #EquipTable
			set AllocAmt = IsNull(AllocAmt,0) + @alloctoadjust
			end
		END
	END
		
    declare bcEMBF cursor local fast_forward for 
	select EMCo, Equip, AllocAmt from #EquipTable
  
    open bcEMBF
    select @opencursor = 1
    
	goto NextEquipRec
	NextEquipRec:
	
	fetch next from bcEMBF into @addemco, @addequip, @addallocamt
	if @@fetch_status <> 0
	begin
			goto EndNextEquipRec 
	end

    select @batchseq = isnull(max(BatchSeq),0) 
	from dbo.EMBF with (nolock) 
	where Co=@emco and Mth=@mth and BatchId=@batchid
    
	select @alloctotal = 0

   	/* create an entry in EMBF for each entry in temp table */
   	/* since batches are unique we can just use a counter to get the seq number */
	--if @addallocamt > 0  Do not have to be positive, only have to be not 0
   	if IsNull(@addallocamt,0) <> 0
   	begin
   		set @batchseq = @batchseq + 1
   		select @EMAHdebitacct=GLDebitAcct from dbo.EMAH with (nolock) where EMCo=@emco and AllocCode=@alloccode
   		if @EMAHdebitacct is null
   		begin
			select @CompOfEquip = null
			--Gets Department of Component
   			select @CompOfEquip=CompOfEquip, @Dept=Department
   			from dbo.EMEM with (nolock) where EMCo = @addemco and Equipment=@addequip
   			if isnull(@CompOfEquip,'') <> ''
			begin
   				select @Dept = Department from dbo.EMEM with (nolock) 
   				where EMCo = @addemco and Equipment=@CompOfEquip
   			end
			--EM Department and Cost Type Override 
			select @EMAHdebitacct = GLAcct 
			from dbo.EMDO with (nolock) 
			where EMCo = @emco and isnull(Department,'') = isnull(@Dept,'') and CostCode = @EMAHcostcode and EMGroup = @emgroup
   			if @EMAHdebitacct is null
			begin
   				select @EMAHdebitacct = GLAcct from dbo.EMDG with (nolock) 
   				where EMCo = @emco and isnull(Department,'') = isnull(@Dept,'') and EMGroup = @emgroup and CostType = @EMAHcosttype
			end

			--Error out if there is no debit GLAccount
	    	if @EMAHdebitacct is null
			begin
    			select @errmsg = 'Missing GLTransAcct for EM Department: ' + convert(varchar(30),isnull(@Dept,''))
   				+ ' Cost Code: ' + convert(varchar(10),isnull(@EMAHcostcode,''))
   				+ ' Cost Type: ' + convert(varchar(10),isnull(@EMAHcosttype,'')),@rcode = 1
    			goto vspexit
    		end 
		end --if @EMAHdebitacct is null
 
	   	if @EMAHmthdateflag = 'M'
			begin
    			update dbo.EMAH 
				set LastPosted = @actualdate, LastMonth = @mth, LastBeginDate = null, LastEndDate = null,
    			PrevPosted = LastPosted,PrevMonth = LastMonth,PrevBeginDate = LastBeginDate,PrevEndDate = LastEndDate
    			where EMCo=@emco and AllocCode=@alloccode
			end
    	else
			begin
    			update dbo.EMAH 
				set LastPosted = @actualdate, LastBeginDate = @begindate, LastEndDate = @enddate, LastMonth = null,
    			PrevPosted = LastPosted,PrevMonth = LastMonth,PrevBeginDate = LastBeginDate,PrevEndDate = LastEndDate
    			where EMCo=@emco and AllocCode=@alloccode

			end	

    	insert into dbo.EMBF(Co, Mth, BatchId, BatchSeq, Source, Equipment, BatchTransType, EMTransType,  EMGroup, CostCode, EMCostType, 
    	ActualDate, Description, GLCo, GLTransAcct, GLOffsetAcct, ReversalStatus,MatlGroup,  UM, Units, Dollars, AllocCode)
    	values(@addemco, @mth, @batchid, @batchseq, 'EMAlloc', @addequip, 'A', 'Alloc', @emgroup, @EMAHcostcode, @EMAHcosttype, @actualdate, 
    	@Description, @EMAHglco, @EMAHdebitacct, @EMAHcreditacct, @reversal, @matlgroup, 'LS', 0, isnull(@addallocamt,0), @alloccode)

    	select @alloctotal = @alloctotal + @addallocamt
    end --if @addallocamt <> 0
      goto NextEquipRec
	
	
	EndNextEquipRec:
		if @opencursor = 1
    	begin
    		close bcEMBF
    		deallocate bcEMBF
    		select @opencursor = 0
    	end
	  
    select @rcode=0
END -- @EMAHallocbasis = 'H' or 'R' or 'V'
------------------------------------------------------
--/*allocation based on amount distributed by Cost */    
if @EMAHallocbasis = 'C'
BEGIN
	--Allocation Type 1-4 are for Date Range
	if @EMAHcostcode is Null and @EMAHcosttype is Null
    	select @AllocType = 1


    if @EMAHcostcode is not  Null and @EMAHcosttype is Null
    	select @AllocType = 2
    if @EMAHcostcode is  Null and @EMAHcosttype is not Null
    	select @AllocType = 3
    if @EMAHcostcode is not Null and @EMAHcosttype is not Null
    	select @AllocType = 4

	--Allocation Type 5-8 are by Month
    if @EMAHmthdateflag = 'M' 
		-- @AllocType(6) = @AllocType(2) + 4
		select @AllocType = @AllocType + 4

	--EMAH.Cosde and EMAH.CostType are null by Date Range
    if @AllocType = 1
    begin
    	select @batchseq = isnull(max(BatchSeq),0) 
		from dbo.EMBF with (nolock) 
		where Co=@emco and Mth=@mth and BatchId=@batchid

    	select @alloctotal = 0

    	select @Equip = min(j.Equipment) 
		from dbo.EMCD j with (nolock)
		Join #EquipTable t on j.EMCo=t.EMCo and j.Equipment=t.Equip and j.EMGroup = t.EMGroup
    	where j.EMCo = @emco and j.EMGroup = @emgroup and j.ActualDate >=@begindate and j.ActualDate <= @enddate
    	while @Equip is not null
    	begin
    		select @CCode = min(CostCode) 
			from dbo.EMCD with (nolock) 
			where EMCo = @emco and Equipment = @Equip and EMGroup = @emgroup and ActualDate >=@begindate and ActualDate <= @enddate
    		while @CCode is not null
    		begin
    			select @CType = min(j.EMCostType) 
				from dbo.EMCD j with (nolock) 
				Inner Join dbo.EMAT c with(nolock)on c.EMCo=j.EMCo and c.EMGroup=j.EMGroup and c.CostType = j.EMCostType
				where j.EMCo = @emco and j.Equipment = @Equip and j.CostCode = @CCode and c.AllocCode = @alloccode 
				and j.EMGroup = @emgroup and j.ActualDate >=@begindate and j.ActualDate <= @enddate 
				while @CType is not null
    			begin
    				select @EMCoInsert = EMCo, @EquipInsert = Equipment, @BasisInsert = sum(Dollars) 
					from dbo.EMCD with (nolock)
    				where EMCo = @emco and Equipment = @Equip and EMGroup = @emgroup and CostCode = @CCode 
					and EMCostType = @CType and ActualDate >=@begindate and ActualDate <= @enddate
    				Group By EMCo, Equipment
    				if @@rowcount = 0 
					begin
						goto skip1
					end

    				select @alloctotal = @alloctotal + @BasisInsert
    				/*if @getbasis=1
    					select @alloctotal = @alloctotal + @BasisInsert
    				else 
    				select @alloctotal = @alloctotal + abs(@BasisInsert)*/
    				insert into #CostTable(EMCo, Equipment, CCode, CType, BasisInsert) 
					values(@EMCoInsert, @EquipInsert, @CCode, @CType, @BasisInsert)
				skip1:
    				select 'CType=' + isnull(CONVERT(varchar(12),@CType),'')

    				select @CType = min(j.EMCostType) 
					from dbo.EMCD j with (nolock) 
					Inner Join dbo.EMAT c with(nolock)on c.EMCo=j.EMCo and c.EMGroup=j.EMGroup and c.CostType = j.EMCostType
					where j.EMCo = @emco and j.Equipment = @Equip and j.EMGroup = @emgroup and j.CostCode = @CCode and c.AllocCode = @alloccode 
					and j.ActualDate >=@begindate and j.ActualDate <= @enddate AND j.EMCostType > @CType
    			end  --while @CType is not null

    			select 'CCode=' + isnull(CONVERT(varchar(12),@CCode),'')

    			select @CCode = min(CostCode)
				from dbo.EMCD with (nolock) 
				where EMCo = @emco and Equipment = @Equip and EMGroup = @emgroup and ActualDate >=@begindate 
				and ActualDate <= @enddate AND CostCode > @CCode
    		end --while @CCode is not null

    		select 'Equipment=' + isnull(CONVERT(varchar(12),@Equip),'')

    		select @Equip = min(j.Equipment) 
			from dbo.EMCD j with (nolock) 
			Join #EquipTable t on j.EMCo=t.EMCo and j.Equipment=t.Equip and j.EMGroup=t.EMGroup
    		where j.EMCo = @emco and j.EMGroup = @emgroup and j.ActualDate >=@begindate and j.ActualDate <= @enddate 
			and j.Equipment > @Equip
    	end --while @Equip is not null
    	if @getbasis=1
    	begin
    		select @basis = @alloctotal
    		select @errmsg = 'Basis returned.', @rcode=0
    		goto vspexit
    	end
		goto donecalculating2
    end --if @AllocType = 1
    
	--EMAH.CostCode is not Null and EMAH.CostType is Null  by Date Range
    if @AllocType = 2
    begin
    	select @batchseq = isnull(max(BatchSeq),0) 
		from dbo.EMBF with (nolock) 
		where Co=@emco and Mth=@mth and BatchId=@batchid

    	select @alloctotal = 0

    	select @Equip = min(j.Equipment)
		from dbo.EMCD j with (nolock) 
		Join #EquipTable t on j.EMCo=t.EMCo and j.Equipment=t.Equip and j.EMGroup=t.EMGroup
    	where j.EMCo = @emco and j.EMGroup = @emgroup and j.ActualDate >=@begindate and j.ActualDate <= @enddate
    	while @Equip is not null
    	begin
    		select @CType = min(j.EMCostType) 
			from dbo.EMCD j with (nolock) 
			Inner Join dbo.EMAT c with(nolock)on c.EMCo=j.EMCo and c.EMGroup=j.EMGroup and c.CostType = j.EMCostType
			where j.EMCo = @emco and j.Equipment = @Equip and c.AllocCode = @alloccode  and j.EMGroup = @emgroup
			and j.ActualDate >=@begindate and j.ActualDate <= @enddate 
			while @CType is not null
    		begin
				select @EMCoInsert = EMCo, @EquipInsert = Equipment, @BasisInsert = sum(Dollars) 
				from dbo.EMCD with (nolock) 
    			where EMCo = @emco and Equipment = @Equip and EMGroup = @emgroup and EMCostType = @CType
				and ActualDate >=@begindate and ActualDate <= @enddate
    			Group By EMCo, Equipment
    			if @@rowcount = 0 
				begin
					goto skip2
				end
    			select @alloctotal = @alloctotal + @BasisInsert
    			/*if @getbasis=1
    				select @alloctotal = @alloctotal + @BasisInsert
    			else 
    			select @alloctotal = @alloctotal + abs(@BasisInsert)*/
    			insert into #CostTable(EMCo, Equipment, CCode, CType, BasisInsert) 
				values(@EMCoInsert, @EquipInsert, @EMAHcostcode, @CType, @BasisInsert)
			skip2:
    			select 'CType=' + isnull(CONVERT(varchar(12),@CType),'')

    			select @CType = min(j.EMCostType) 
				from dbo.EMCD j with (nolock)
				Inner Join dbo.EMAT c with(nolock)on c.EMCo=j.EMCo and c.EMGroup=j.EMGroup and c.CostType = j.EMCostType
				where j.EMCo = @emco and j.Equipment = @Equip and c.AllocCode = @alloccode and j.EMGroup = @emgroup
				and j.ActualDate >=@begindate and j.ActualDate <= @enddate 	AND j.EMCostType > @CType
    		end  --while @CType is not null
    		
			select 'Equipment=' + isnull(CONVERT(varchar(12),@Equip),'')
    		
			select @Equip = min(j.Equipment) 
			from dbo.EMCD j with (nolock) 
			Join #EquipTable t on j.EMCo=t.EMCo and j.Equipment=t.Equip and j.EMGroup=t.EMGroup
    		where j.EMCo = @emco and j.EMGroup = @emgroup and j.ActualDate >=@begindate and j.ActualDate <= @enddate 
			and j.Equipment > @Equip
    	end --while @Equip is not null
		if @getbasis=1
    	begin
    		select @basis = @alloctotal
    		select @errmsg = 'Basis returned.', @rcode=0
    		goto vspexit
    	end
		goto donecalculating2
    end --if @AllocType = 2
    
	--EMAH.CostCode is  Null and EMAH.CostType is not Null by Date Range
    if @AllocType = 3
    begin
    	select @batchseq = isnull(max(BatchSeq),0)
		from dbo.EMBF with (nolock) 
		where Co=@emco and Mth=@mth and BatchId=@batchid

    	select @alloctotal = 0

    	select @Equip = min(j.Equipment)
		from dbo.EMCD j with (nolock) 
		Join #EquipTable t on j.EMCo=t.EMCo and j.Equipment=t.Equip and j.EMGroup=t.EMGroup
    	where j.EMCo = @emco and j.EMGroup = @emgroup and j.ActualDate >=@begindate and j.ActualDate <= @enddate
    	while @Equip is not null
    	begin
    		select @CCode = min(CostCode) 
			from dbo.EMCD with (nolock) 
			where EMCo = @emco and Equipment = @Equip and EMGroup=@emgroup and ActualDate >=@begindate and ActualDate <= @enddate
    		while @CCode is not null
    		begin
    			select @EMCoInsert = j.EMCo, @EquipInsert = j.Equipment, @BasisInsert = sum(Dollars) 
				from dbo.EMCD j with (nolock) 
				Inner Join dbo.EMAT c with(nolock)on c.EMCo=j.EMCo and c.EMGroup=j.EMGroup and c.CostType = j.EMCostType
    			where j.EMCo = @emco and j.Equipment = @Equip and j.CostCode = @CCode and j.EMGroup=@emgroup and c.AllocCode=@alloccode 
				and ActualDate >=@begindate and ActualDate <= @enddate
				Group By j.EMCo, j.Equipment
    			if @@rowcount = 0 
				begin
					goto skip3
				end
    			select @alloctotal = @alloctotal + @BasisInsert
    			/*if @getbasis=1
    				select @alloctotal = @alloctotal + @BasisInsert
    			else 
    				select @alloctotal = @alloctotal + abs(@BasisInsert)*/
    			select 'EquipInsert=' + isnull(CONVERT(varchar(12),@EquipInsert),'')
    			select 'CCode=' + isnull(CONVERT(varchar(12),@CCode),'')
    			select 'CostType=' + isnull(CONVERT(varchar(12),@EMAHcosttype),'')
    			select 'BasisInsert=' + isnull(CONVERT(varchar(12),@BasisInsert),'')
    			insert into #CostTable(EMCo, Equipment, CCode, CType, BasisInsert)
    			values(@EMCoInsert, @EquipInsert, @CCode, @EMAHcosttype, @BasisInsert)
			skip3:
    			select @CCode = min(CostCode)
				from dbo.EMCD with (nolock) 
    			where EMCo = @emco and Equipment = @Equip and EMGroup=@emgroup and ActualDate >=@begindate and ActualDate <= @enddate 
				AND CostCode > @CCode
    		end --while @CCode is not null
    		
			select @Equip = min(j.Equipment) 
			from dbo.EMCD j with (nolock) 
			Join #EquipTable t on j.EMCo=t.EMCo and j.Equipment=t.Equip and j.EMGroup=t.EMGroup
    		where j.EMCo = @emco and j.EMGroup=@emgroup and j.ActualDate >=@begindate and j.ActualDate <= @enddate and j.Equipment > @Equip
    	end --while @Equip is not null
    
    	if @getbasis=1
    	begin
			select @basis = @alloctotal
    		select @errmsg = 'Basis returned.', @rcode=0
    		goto vspexit
    	end
    	goto donecalculating2
    end --if @AllocType = 3
    
	--EMAH.CostCode is not Null and EMAH.CostType is not Null  by Date Range
    if @AllocType = 4
    begin
    	select @batchseq = isnull(max(BatchSeq),0)
		from dbo.EMBF with (nolock)
		where Co=@emco and Mth=@mth and BatchId=@batchid

    	select @alloctotal = 0

    	select @Equip = min(j.Equipment)
    	from dbo.EMCD j 
		Join #EquipTable t on j.EMCo=t.EMCo and j.Equipment=t.Equip and j.EMGroup=t.EMGroup
		where j.EMCo = @emco and j.EMGroup=@emgroup and j.ActualDate >=@begindate and j.ActualDate <= @enddate
    	while @Equip is not null
    	begin
    		select @EMCoInsert = j.EMCo, @EquipInsert = j.Equipment, @BasisInsert = sum(Dollars) 
			from dbo.EMCD j with (nolock) 
			Inner Join dbo.EMAT c with(nolock)on c.EMCo=j.EMCo and c.EMGroup=j.EMGroup and c.CostType = j.EMCostType
    		where j.EMCo = @emco and j.Equipment = @Equip and j.EMGroup=@emgroup and c.AllocCode=@alloccode 
			and ActualDate >= @begindate and ActualDate <= @enddate
			Group By j.EMCo, j.Equipment
    		if @@rowcount = 0 
			begin 
				goto skip4
			end
			select @alloctotal = @alloctotal + @BasisInsert
    		/*if @getbasis=1
    			select @alloctotal = @alloctotal + @BasisInsert
    		else 
    			select @alloctotal = @alloctotal + abs(@BasisInsert)*/
    		insert into #CostTable(EMCo, Equipment, CCode, CType, BasisInsert) 
			values(@EMCoInsert, @EquipInsert, @EMAHcostcode, @EMAHcosttype, @BasisInsert)
		skip4:
    		select 'Equipment=' + isnull(CONVERT(varchar(12),@Equip),'')

    		select @Equip = min(j.Equipment) 
			from dbo.EMCD j with (nolock)
			Join #EquipTable t on j.EMCo=t.EMCo and j.EMGroup =t.EMGroup and j.Equipment=t.Equip
    		where j.EMCo = @emco and j.EMGroup=@emgroup and j.ActualDate >=@begindate and j.ActualDate <= @enddate and j.Equipment > @Equip
    	end --while @Equip is not null
    	if @getbasis=1
    	begin
    		select @basis = @alloctotal
    		select @errmsg = 'Basis returned.', @rcode=0
    		goto vspexit
    	end
    	goto donecalculating2
    end --if @AllocType = 4
    
	--EMAH.Cosde and EMAH.CostType are null by Month
    if @AllocType = 5
    begin
    	select @batchseq = isnull(max(BatchSeq),0) 
		from dbo.EMBF with (nolock) 
		where Co=@emco and Mth=@mth and BatchId=@batchid

    	select @alloctotal = 0

    	select @Equip = min(j.Equipment)
		from dbo.EMCD j with (nolock) 
		Join #EquipTable t on j.EMCo=t.EMCo and j.Equipment=t.Equip and j.EMGroup=t.EMGroup
    	where j.EMCo = @emco and j.EMGroup=@emgroup and j.Mth=@mth
    	while @Equip is not null
    	begin
    		select @CCode = min(CostCode) 
			from dbo.EMCD with (nolock) 
			where EMCo = @emco and Equipment = @Equip and EMGroup=@emgroup and Mth=@mth
    		while @CCode is not null
    		begin
    			select @CType = min(j.EMCostType) 
				from dbo.EMCD j with (nolock) 
				Inner Join dbo.EMAT c with(nolock)on c.EMCo=j.EMCo and c.EMGroup=j.EMGroup and c.CostType = j.EMCostType
    			where j.EMCo = @emco and j.Equipment = @Equip and j.EMGroup=@emgroup and c.AllocCode=@alloccode and j.CostCode = @CCode 
				and j.Mth=@mth 
    			while @CType is not null
    			begin
    				select @EMCoInsert = EMCo, @EquipInsert = Equipment, @BasisInsert = sum(Dollars) 
					from dbo.EMCD with (nolock) 
    				where EMCo = @emco and Equipment = @Equip and EMGroup=@emgroup and CostCode = @CCode 
					and EMCostType = @CType and Mth=@mth
					Group By EMCo, Equipment
    				if @@rowcount = 0 
					begin 
						goto skip5
					end
    				select @alloctotal = @alloctotal + @BasisInsert
    				/*if @getbasis=1
    					select @alloctotal = @alloctotal + @BasisInsert
    				else 
    				select @alloctotal = @alloctotal + abs(@BasisInsert)*/
    				insert into #CostTable(EMCo, Equipment, CCode, CType, BasisInsert) 
					values(@EMCoInsert, @EquipInsert, @CCode, @CType, @BasisInsert)
				skip5:
    				select 'CType=' + isnull(CONVERT(varchar(12),@CType),'')
    				
					select @CType = min(j.EMCostType)
					from dbo.EMCD j with (nolock) 
					Inner Join dbo.EMAT c with(nolock)on c.EMCo=j.EMCo and c.EMGroup=j.EMGroup and c.CostType = j.EMCostType
    				where j.EMCo = @emco and j.Equipment = @Equip and j.CostCode = @CCode and j.Mth=@mth AND 
					j.EMGroup=@emgroup and c.AllocCode=@alloccode AND j.EMCostType > @CType
    			end  --while @CType is not null
    			select 'CCode=' + isnull(CONVERT(varchar(12),@CCode),'')

    			select @CCode = min(CostCode)
				from dbo.EMCD with (nolock) 
				where EMCo = @emco and Equipment = @Equip and EMGroup=@emgroup and Mth=@mth aND CostCode > @CCode
    		end --while @CCode is not null
    		select 'Equipment=' + isnull(CONVERT(varchar(12),@Equip),'')

    		select @Equip = min(j.Equipment) 
			from dbo.EMCD j with (nolock) 
			Join #EquipTable t on j.EMCo=t.EMCo and j.Equipment=t.Equip and j.EMGroup=t.EMGroup
    		where j.EMCo = @emco and j.Mth=@mth and j.Equipment > @Equip
		end --while @Equip is not null
		if @getbasis=1
		begin
    		select @basis = @alloctotal
    		select @errmsg = 'Basis returned.', @rcode=0
    		goto vspexit
		end
		goto donecalculating2
    end --if @AllocType = 5
    
	--EMAH.CostCode is not Null and EMAH.CostType is Null by Month
    if @AllocType = 6
    begin
    	select @batchseq = isnull(max(BatchSeq),0)
		from dbo.EMBF with (nolock) 
		where Co=@emco and Mth=@mth and BatchId=@batchid

    	select @alloctotal = 0

    	select @Equip = min(j.Equipment) 
		from dbo.EMCD j with (nolock) 
		Join #EquipTable t on j.EMCo=t.EMCo and j.Equipment=t.Equip  and j.EMGroup=t.EMGroup
		where j.EMCo = @emco and j.EMGroup=@emgroup and j.Mth=@mth
    	while @Equip is not null
    	begin
    		select @CType = min(j.EMCostType)
			from dbo.EMCD j with (nolock) 
			Inner Join dbo.EMAT c with(nolock)on c.EMCo=j.EMCo and c.EMGroup=j.EMGroup and c.CostType = j.EMCostType
    		where j.EMCo = @emco and j.Equipment = @Equip and j.Mth=@mth  and j.EMGroup=@emgroup and c.AllocCode=@alloccode
    		while @CType is not null
    		begin
    			select @EMCoInsert = EMCo, @EquipInsert = Equipment, @BasisInsert = sum(Dollars) 
				from dbo.EMCD with (nolock) 
    			where EMCo = @emco and Equipment = @Equip and EMGroup=@emgroup and EMCostType = @CType and Mth=@mth
    			Group By EMCo, Equipment
    			if @@rowcount = 0 
				begin 
					goto skip6
				end
    			select @alloctotal = @alloctotal + @BasisInsert
    			/*if @getbasis=1
    				select @alloctotal = @alloctotal + @BasisInsert
    			else 
    				select @alloctotal = @alloctotal + abs(@BasisInsert)*/
    			insert into #CostTable(EMCo, Equipment, CCode, CType, BasisInsert) 
				values(@EMCoInsert, @EquipInsert, @EMAHcostcode, @CType, @BasisInsert)
			skip6:
    			select 'CType=' + isnull(CONVERT(varchar(12),@CType),'')
    			
				select @CType = min(j.EMCostType) 
				from dbo.EMCD j with (nolock) 
				Inner Join dbo.EMAT c with(nolock)on c.EMCo=j.EMCo and c.EMGroup=j.EMGroup and c.CostType = j.EMCostType
				where j.EMCo = @emco and j.Equipment = @Equip and j.Mth=@mth AND j.EMGroup=@emgroup and c.AllocCode=@alloccode
				and j.EMCostType > @CType
    		end  --while @CType is not null
    		select 'Equipment=' + isnull(CONVERT(varchar(12),@Equip),'')

    		select @Equip = min(j.Equipment) 
			from dbo.EMCD j with (nolock) 
			Join #EquipTable t on j.EMCo=t.EMCo and j.Equipment=t.Equip and j.EMGroup=t.EMGroup
    		where j.EMCo = @emco and j.Mth=@mth and j.EMGroup=@emgroup and j.Equipment > @Equip
    	end --while @Equip is not null
    	if @getbasis=1
    	begin
    		select @basis = @alloctotal
    		select @errmsg = 'Basis returned.', @rcode=0
    		goto vspexit
    	end
    	goto donecalculating2
    end --if @AllocType = 6
    
	--EMAH.CostCode is  Null and EMAH.CostType is not Null by Month
    if @AllocType = 7
    begin
    	select @batchseq = isnull(max(BatchSeq),0) 
		from dbo.EMBF with (nolock)
		where Co=@emco and Mth=@mth and BatchId=@batchid

    	select @alloctotal = 0

    	select @Equip = min(j.Equipment)
		from dbo.EMCD j with (nolock) 
		Join #EquipTable t on j.EMCo=t.EMCo and j.Equipment=t.Equip and j.EMGroup=t.EMGroup
		where j.EMCo = @emco and j.EMGroup=@emgroup and j.Mth=@mth
    	while @Equip is not null
    	begin
    		select @CCode = min(CostCode) 
			from dbo.EMCD with (nolock) 
			where EMCo = @emco and Equipment = @Equip and EMGroup=@emgroup and Mth=@mth
    		while @CCode is not null
    		begin
    			select @EMCoInsert = j.EMCo, @EquipInsert = j.Equipment, @BasisInsert = sum(Dollars) 
				from dbo.EMCD j with (nolock) 
				Inner Join dbo.EMAT c with(nolock)on c.EMCo=j.EMCo and c.EMGroup=j.EMGroup and c.CostType = j.EMCostType
    			where j.EMCo = @emco and j.Equipment = @Equip and j.CostCode = @CCode 
				and Mth=@mth and j.EMGroup=@emgroup and c.AllocCode=@alloccode
    			Group By j.EMCo, j.Equipment
    			if @@rowcount = 0 
				begin
					goto skip7
				end
				select @alloctotal = @alloctotal + @BasisInsert
    			/*if @getbasis=1
    				select @alloctotal = @alloctotal + @BasisInsert
    			else 
    				select @alloctotal = @alloctotal + abs(@BasisInsert)*/
    			insert into #CostTable(EMCo, Equipment, CCode, CType, BasisInsert) 
				values(@EMCoInsert, @EquipInsert, @CCode, @EMAHcosttype, @BasisInsert)
			skip7:
    			select 'CCode=' + isnull(CONVERT(varchar(12),@CCode),'')
    		
				select @CCode = min(CostCode) 
				from dbo.EMCD with (nolock) 
				where EMCo = @emco and Equipment = @Equip and EMGroup=@emgroup and Mth=@mth AND CostCode > @CCode
    		end --while @CCode is not null
    		select 'Equipment=' + isnull(CONVERT(varchar(12),@Equip),'')

    		select @Equip = min(j.Equipment) 
			from dbo.EMCD j with (nolock) 
			Join #EquipTable t on j.EMCo=t.EMCo and j.Equipment=t.Equip and j.Equipment=t.Equip
    		where j.EMCo = @emco and j.EMGroup=@emgroup and j.Mth=@mth and j.Equipment > @Equip
    	end --while @Equip is not null
    	if @getbasis=1
    	begin
    		select @basis = @alloctotal
    		select @errmsg = 'Basis returned.', @rcode=0
    		goto vspexit
    	end
    	goto donecalculating2
    end --if @AllocType = 7
    
	--EMAH.CostCode is not Null and EMAH.CostType is not Null by Month
    if @AllocType = 8
    begin
    	select @batchseq = isnull(max(BatchSeq),0)
		from dbo.EMBF with (nolock) 
		where Co=@emco and Mth=@mth and BatchId=@batchid

    	select @alloctotal = 0

    	select @Equip = min(j.Equipment)
		from dbo.EMCD j with (nolock) 
		Join #EquipTable t on j.EMCo=t.EMCo and j.Equipment=t.Equip and j.EMGroup=t.EMGroup
		where j.EMCo = @emco and j.EMGroup=@emgroup and j.Mth=@mth
    	while @Equip is not null
    	begin
    		select @EMCoInsert = j.EMCo, @EquipInsert = j.Equipment, @BasisInsert = sum(Dollars) 
			from dbo.EMCD j with (nolock) 
			Inner Join dbo.EMAT c with(nolock)on c.EMCo=j.EMCo and c.EMGroup=j.EMGroup and c.CostType = j.EMCostType
    		where j.EMCo = @emco and j.Equipment = @Equip and j.EMGroup=@emgroup and c.AllocCode=@alloccode and Mth=@mth
    		Group By j.EMCo, j.Equipment
    		if @@rowcount = 0
			begin
				 goto skip8
			end
    		select @alloctotal = @alloctotal + @BasisInsert
    		/*if @getbasis=1
    			select @alloctotal = @alloctotal + @BasisInsert
    		else 
    			select @alloctotal = @alloctotal + abs(@BasisInsert)*/
    		insert into #CostTable(EMCo, Equipment, CCode, CType, BasisInsert)
			values(@EMCoInsert, @Equip, @EMAHcostcode, @EMAHcosttype, @BasisInsert)

	skip8:

    		select 'Equipment=' + isnull(CONVERT(varchar(12),@Equip),'')

    		select @Equip = min(j.Equipment)
			from dbo.EMCD j with (nolock)
			Join #EquipTable t on j.EMCo=t.EMCo and j.Equipment=t.Equip and j.EMGroup=t.EMGroup
			where j.EMCo = @emco and j.EMGroup=@emgroup and j.Mth=@mth and j.Equipment > @Equip
    	end --while @Equip is not null
    	if @getbasis=1
    	begin
    		select @basis = @alloctotal
    		select @errmsg = 'Basis returned.', @rcode=0
    		goto vspexit
    	end
    	goto donecalculating2
    end --if @AllocType = 8

/* now each row in #CostTable should coorespond to a Batch Entry */    
donecalculating2:
	/*Issue 131076
	if we're allocating an amount, and not using a column in JCJM check and
	make sure that we allocated the full amount
	if there is a rounding descrepency we add it to the last item
	If amount remaining to allocate, adjust last batch seq with difference. for non-user memo amounts only*/
	--134913 added "and @EMAHamtrateflag<>'C'"
	if @EMAHamtcolumn is not null  and @EMAHamtrateflag<>'C'
	begin
		If @allocamt is not null
		begin
			select @alloctoadjust = @allocamt - sum(BasisInsert) from #CostTable

			if @alloctoadjust <> 0 
			begin
				update Top (1) #CostTable 
				set BasisInsert =  IsNull(BasisInsert,0) + @alloctoadjust
			end
		end
	END

	
	declare bcEMBF2 cursor local fast_forward for
	select EMCo, Equipment, CCode, CType, BasisInsert from #CostTable

    open bcEMBF2
    select @opencursor2 = 1

	goto NextCostRec
	NextCostRec:

	fetch next from bcEMBF2 into @costemco, @costequip, @costccode, @costctype, @costBasisInsert 

	if @@fetch_status <> 0
	begin
			goto EndNextCostRec
	end
	
	select @batchseq = isnull(max(BatchSeq),0) 
	from dbo.EMBF with (nolock) where Co=@emco and Mth=@mth and BatchId=@batchid

    if @alloctotal  = 0
    begin
    	select @errmsg = 'Basis is 0, cannot create Allocations!', @rcode=1
    	goto vspexit
    end
     
	/* create an entry in EMBF for each entry in temp table */
	/* since batches are unique we can just use a counter to get the seq number */
   	if isnull(@costBasisInsert,0) <> 0
   	begin
   		select @VEMCo = @costemco
   		if @EMAHratecolumn is not null
   		begin
   			exec('declare EM_cursor cursor global for select ' + @EMAHratecolumn + ' from dbo.EMEM with(nolock) where EMCo = ' + @VEMCo + ' and Equipment = ''' + @costequip + '''')
   			open EM_cursor
   			fetch next from EM_cursor into @allocrate
   			close EM_cursor
   			deallocate EM_cursor
   		end --if @EMAHratecolumn is not null
   		if @EMAHamtcolumn is not null
   		begin
   			exec('declare EM_cursor cursor global for select ' + @EMAHamtcolumn + ' from dbo.EMEM  with(nolock) where EMCo = ' + @VEMCo + ' and Equipment = ''' + @costequip + '''')
   			open EM_cursor
   			fetch next from EM_cursor into @allocamt
   			close EM_cursor
   			deallocate EM_cursor
   		end --if @EMAHamtcolumn is not null
    
		/* once basis has been calculated then we can calculate the allocation based on Type */
 		if @EMAHamtrateflag = 'A'
		begin
   			select @costBasisInsert = case when @costBasisInsert < 0 then ((abs(@costBasisInsert) / @alloctotal) * @allocamt) * -1 else ((abs(@costBasisInsert) / @alloctotal) * @allocamt) end
		end
    	if @EMAHamtrateflag = 'C'
		begin
    		select @costBasisInsert = @allocamt
		end
    	if @EMAHamtrateflag = 'R' or @EMAHamtrateflag = 'T'
		begin
    		select @costBasisInsert = @costBasisInsert * @allocrate
		End

    	select @batchseq = @batchseq + 1

		select @EMAHdebitacct=GLDebitAcct 
		from dbo.EMAH with (nolock) 
		where EMCo=@emco and AllocCode=@alloccode
		if @EMAHdebitacct is null
   		begin
   			select @Dept = Department from dbo.EMEM with (nolock) 
  			where EMCo = @costemco and Equipment = @costequip
	    	
			select @EMAHdebitacct = GLAcct from dbo.EMDO with (nolock) 
   			where EMCo = @emco and isnull(Department,'') = isnull(@Dept,'') 
			and CostCode = @costccode and EMGroup = @emgroup

	    	if @EMAHdebitacct is null
			begin
    			select @EMAHdebitacct = GLAcct from dbo.EMDG with (nolock) 
   				where EMCo = @emco and isnull(Department,'') = isnull(@Dept,'') 
				and EMGroup = @emgroup and CostType = @costctype
			end
	
   			if @EMAHdebitacct is null
			begin
				select @errmsg = 'Missing GLTransAcct for EMDepartment ' + isnull(convert(varchar(30),@Dept),'')
								+ ' Cost Type ' + isnull(convert(varchar(10),@EMAHcosttype),''),@rcode = 1
				goto vspexit
			end
    	end --if @EMAHdebitacct is null
    
    	if @EMAHmthdateflag = 'M'
			begin
    			update dbo.EMAH 
				set LastPosted = @actualdate, LastMonth = @mth, LastBeginDate = null, LastEndDate = null,
    			PrevPosted = LastPosted,PrevMonth = LastMonth,PrevBeginDate = LastBeginDate,PrevEndDate = LastEndDate
    			where EMCo=@emco and AllocCode=@alloccode
			end
    	else
			begin
    			update dbo.EMAH 
				set LastPosted = @actualdate, LastBeginDate = @begindate, LastEndDate = @enddate, LastMonth = null,
    			PrevPosted = LastPosted,PrevMonth = LastMonth,PrevBeginDate = LastBeginDate,PrevEndDate = LastEndDate
    			where EMCo=@emco and AllocCode=@alloccode
			end

   		insert into dbo.EMBF(Co,Mth,BatchId,BatchSeq,Source,Equipment,BatchTransType,EMTransType,EMGroup,CostCode,EMCostType,ActualDate,
		Description,GLCo,GLTransAcct,GLOffsetAcct, ReversalStatus,MatlGroup, UM, Units, Dollars,AllocCode)
    	values(@costemco,@mth,@batchid,@batchseq,'EMAlloc',@costequip,'A','Alloc',@emgroup,@costccode,@costctype,@actualdate,
		@Description,@EMAHglco,@EMAHdebitacct,@EMAHcreditacct,@reversal,@matlgroup,'LS',0,isnull(@costBasisInsert,0),@alloccode)
	end 
	goto NextCostRec
  
    
	EndNextCostRec:
		if @opencursor2 = 1
    		begin
    			close bcEMBF2
    			deallocate bcEMBF2
    			select @opencursor2 = 0
    		end
    	--136527
	if @allocamt is not null  and @EMAHamtrateflag='A'
	begin
		select @alloctoadjust = @allocamt - sum(Dollars) from dbo.EMBF 
		where Co=@costemco and Mth=@mth and @batchid=BatchId and Source='EMAlloc' and AllocCode=@alloccode
		and ActualDate = @actualdate
		
		if @alloctoadjust <> 0 
			begin
				update Top (1) dbo.EMBF 
				set Dollars =  IsNull(Dollars,0) + @alloctoadjust 
				where Co=@costemco and Mth=@mth and @batchid=BatchId and Source='EMAlloc' and AllocCode=@alloccode
				and ActualDate = @actualdate
			end
		end
	   	select @rcode=0
END--if @EMAHallocbasis = 'C'


vspexit:
    	if @opencursor = 1
		begin
	    	close bcEMBF
    		deallocate bcEMBF
    		select @opencursor = 0
    	end
       	drop table #EquipTable
    
    	if @opencursor2 = 1
    	begin
    		close bcEMBF2
    		deallocate bcEMBF2
    		select @opencursor2 = 0
    	end
	   	drop table #CostTable

return @rcode


GO
GRANT EXECUTE ON  [dbo].[vspEMACProcess] TO [public]
GO
