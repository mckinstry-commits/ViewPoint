SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/************************************************/
CREATE PROCEDURE [dbo].[bspEMPurgeHistory]
/***********************************************************
* CREATED BY: bc  09/07/99
* MODIFIED By :  bc 05/09/00   removed restraints that prevented EMCD or EMMR records from being deleted
*                              if a parent transaction existed in another table.  issue 6021
*				TV 04/17/03 Allow deleteion of EMLH records if OutDate and @locDate are null #20887
*				TV 02/11/04 - 23061 added isnulls
*				CHS 02/18/08 issue # 119999
*				AMR 01/12/11 - Issue #142350, making case sensitive by removing unused vars and renaming same named variables
*               ECV 04/14/11 - 143370 - TK-04234 - Fix delete of records with missing DateOut - Add missing where parameters on delete statements.
*
* USAGE:
*	deletes equipment from detail and history tables.  does not delete from master table.
*  the order of deletion is important, since some of these tables are dependant upon each other.
*
*
* INPUT PARAMETERS
*  @emco		EM Company
*  @optData     search by (E)quipment, (C)ategory, Componen(T), (A)ll
*  @equip		Equipment to search on
*  @catgy      Category to search on
*  @component  Componenet to search on
*  @chkMeter, @meterdate
*  @checkCost, @costmth
*  @chkLoc, @locdate
*  @chkRev, @revmth
*  @chkWO, @wodate
*  @chkComp, @compdate
*
* OUTPUT PARAMETERS
*  @found      Yes if there is at least one attachment.  No if there are no attachments
*	@msg		Description or Error msg if error
*
* RETURN VALUE:
* 	0 	    Success
*	1 & message Failure
**********************************************************/
(@emco bCompany, @optData char(1), @equip bEquip, @catgy bCat, @component bEquip, @chkMeter bYN, @metermth bMonth, 
 @chkCost bYN, @costmth bMonth, @chkLoc bYN, @locdate bDate, @chkComp bYN, @compdate bDate, @chkRev bYN, 
 @revmth bMonth, @chkWO bYN, @wodate bDate, @chkLastXferRecord bYN, @errmsg varchar(255) output)
as
set nocount on

declare @rcode int, @cnt int, @wo varchar(10), @woitem bItem, @mth bMonth, @trans bTrans

select @rcode = 0

if @emco is null
   	begin
   	select @errmsg = 'Missing EM Company!', @rcode = 1
   	goto bspexit
   	end

if @optData is null
   	begin
   	select @errmsg = 'Missing search option!', @rcode = 1
   	goto bspexit
   	end



/************************************/
if @optData = 'E'
	Begin
	---- purge equipment out of location history table
   	if @chkLoc = 'Y'
   		begin
   		-- Delete all records for this equipment with no DateOut
		DELETE EMLH where EMCo = @emco and Equipment = @equip And DateOut IS NULL
		AND NOT KeyID IN (select top 1 KeyID
			from EMLH where EMCo = @emco and Equipment = @equip and DateOut is null
			order by DateIn DESC, Trans DESC
		)

		if isnull(@locdate,'') <> '' 
			begin
			---- delete all EMLH records where we have an date out less than equal to the @locdate
			delete from EMLH where EMCo = @emco and Equipment = @equip and DateOut is not null and DateOut <= @locdate

			---- check and delete last record if @chkLastXferRecord = 'Y' and we only have one record left in EMLH
			if @chkLastXferRecord = 'Y'
				begin
				if (select count(*) from EMLH where EMCo = @emco and Equipment = @equip) = 1
					begin
					delete from EMLH where EMCo = @emco and Equipment = @equip
					end
				end
			end
		else
			begin
			---- if no location date restriction is provided, delete all records
			delete bEMLH where EMCo = @emco and Equipment = @equip
			end
		end


   	/* purge equipment out of revenue detail tables */
   	if @chkRev = 'Y'
   		begin
   		select @mth = min(Mth) from EMRD where EMCo = @emco and Equipment = @equip and Mth <= @revmth
   		while @mth is not null
   			begin
   			select @trans = min(Trans) from EMRD where EMCo = @emco and Mth = @mth and Equipment = @equip
   			while @trans is not null
   				begin
   				delete bEMRD where EMCo = @emco and Mth = @mth and Trans = @trans
   				select @trans = min(Trans) from EMRD where EMCo = @emco and Mth = @mth and Equipment = @equip and Trans > @trans
   				end
   			select @mth = min(Mth) from EMRD where EMCo = @emco and Equipment = @equip and Mth < = @revmth and Mth > @mth
   			end
   		end
   
   	/* purge equipment out of cost detail table */
   	if @chkCost = 'Y'
   		begin
   		select @mth = min(Mth) from EMCD where EMCo = @emco and Mth <= @costmth and Equipment = @equip
   		while @mth is not null
   			begin
   			select @trans = min(EMTrans) from EMCD where EMCo = @emco and Mth = @mth and Equipment = @equip
   			while @trans is not null
   				begin
   				delete EMCD where EMCo = @emco and Mth = @mth and EMTrans = @trans
   				select @trans = min(EMTrans) from EMCD where EMCo = @emco and Mth = @mth and Equipment = @equip and EMTrans > @trans
   				end
   			select @mth = min(Mth) from EMCD where EMCo = @emco and Equipment = @equip and Mth <= @costmth and Mth > @mth
   			end
   		end
   
   	/* purge equipment out of work order tables */
   	if @chkWO = 'Y'
   		Begin
   		select @wo = min(WorkOrder) from EMWI where EMCo = @emco and Equipment = @equip and DateCompl is not null and DateCompl <= @wodate
   		while @wo is not null
   			begin
   			select @woitem = min(WOItem) from EMWI where EMCo = @emco and Equipment = @equip and WorkOrder = @wo and DateCompl is not null and DateCompl <= @wodate
   			while @woitem is not null
   				begin
   				/* work order parts table */
   				delete bEMWP where EMCo = @emco and Equipment = @equip and WorkOrder = @wo and WOItem = @woitem
   				select @woitem = min(WOItem) from EMWI where EMCo = @emco and Equipment = @equip and WorkOrder = @wo and DateCompl is not null and DateCompl <= @wodate and WOItem > @woitem
   				end
   			/* work order items table */
   			delete bEMWI where EMCo = @emco and Equipment = @equip and WorkOrder = @wo and DateCompl is not null and DateCompl <= @wodate
   			/* work order header table */
   			if not exists(select * from EMWI where EMCo = @emco and Equipment = @equip and WorkOrder= @wo)
   				begin
   				delete bEMWH where EMCo = @emco and Equipment = @equip and WorkOrder = @wo
   				end
   			select @wo = min(WorkOrder) from EMWI where EMCo = @emco and Equipment = @equip and DateCompl is not null and DateCompl <= @wodate and WorkOrder > @wo
   			end
   		End
   
   	/* purge equipment out of meter reading table after potential passes through EMCD and EMRD */
   	if @chkMeter = 'Y'
   		begin
   		select @mth = min(Mth) from EMMR	where EMCo = @emco and Equipment = @equip and Mth <= @metermth
   		while @mth is not null
   			begin
   			select @trans = min(EMTrans) from EMMR where EMCo = @emco and Mth = @mth and Equipment = @equip
   			while @trans is not null
   				begin
   				delete bEMMR where EMCo = @emco and Mth = @mth and EMTrans = @trans
   				select @trans = min(EMTrans) from EMMR where EMCo = @emco and Mth = @mth and Equipment = @equip and EMTrans > @trans
   				end
   	
   			select @mth = min(Mth) from EMMR where EMCo = @emco and Equipment = @equip and Mth <= @metermth and Mth > @mth
   			end
   		end
   	End


/************************************/
if @optData = 'C'
   	Begin
   	select @equip = min(Equipment) from EMEM where EMCo = @emco and Type = 'E' and Category = @catgy
   	while @equip is not null
		Begin
   		---- purge equipment out of location history table
   		if @chkLoc = 'Y'
			begin
			if isnull(@locdate,'') <> ''
				begin
       			select @mth = min(Month) from EMLH 
				where EMCo = @emco and Equipment = @equip and DateOut is not null and DateOut <= @locdate
       			while @mth is not null
       				begin
       				select @trans = min(Trans) from EMLH 
					where EMCo = @emco and Month = @mth and Equipment = @equip and DateOut is not null and DateOut <= @locdate
       				while @trans is not null
       					begin

       					delete bEMLH where EMCo = @emco and Month = @mth and Trans = @trans

       					select @trans = min(Trans) from EMLH 
						where EMCo = @emco and Month = @mth and Equipment = @equip and DateOut is not null and DateOut <= @locdate and Trans > @trans
       					end
       				select @mth = min(Month) from EMLH 
					where EMCo = @emco and Equipment = @equip and DateOut is not null and DateOut <= @locdate and Month > @mth
       				end
				end
			else
				begin
				---- if no location date restriction is provided, delete all records
				delete bEMLH where EMCo = @emco and Equipment = @equip
				end
			end

   		/* purge equipment out of revenue detail tables */
   		if @chkRev = 'Y'
   			begin
   			select @mth = min(Mth) from EMRD where EMCo = @emco and Mth <= @revmth and Equipment = @equip
   			while @mth is not null
   				begin
   				select @trans = min(Trans) from EMRD where EMCo = @emco and Mth = @mth and Equipment = @equip
   				while @trans is not null
   					begin
   					delete bEMRD where EMCo = @emco and Mth = @mth and Trans = @trans
   					select @trans = min(Trans) from EMRD where EMCo = @emco and Mth = @mth and Equipment = @equip and Trans > @trans
   					end
   				select @mth = min(Mth) from EMRD where EMCo = @emco and Equipment = @equip and Mth < = @revmth and Mth > @mth
   				end
   			end
   	
   		/* purge equipment out of cost detail table */
   		if @chkCost = 'Y'
   			begin
   			select @mth = min(Mth) from EMCD where EMCo = @emco and Mth <= @costmth and Equipment = @equip
   			while @mth is not null
   				begin
   				select @trans = min(EMTrans) from EMCD where EMCo = @emco and Mth = @mth and Equipment = @equip
   				while @trans is not null
   					begin
   					delete EMCD where EMCo = @emco and Mth = @mth and EMTrans = @trans
   					select @trans = min(EMTrans) from EMCD where EMCo = @emco and Mth = @mth and Equipment = @equip and EMTrans > @trans
   					end
   				select @mth = min(Mth) from EMCD where EMCo = @emco and Equipment = @equip and Mth <= @costmth and Mth > @mth
   				end
   			end
   	
   		/* purge equipment out of work order tables */
   		if @chkWO = 'Y'
   			Begin
   			select @wo = min(WorkOrder) from EMWI where EMCo = @emco and Equipment = @equip and DateCompl is not null and DateCompl <= @wodate
   			while @wo is not null
   				begin
   				select @woitem = min(WOItem) from EMWI where EMCo = @emco and Equipment = @equip and WorkOrder = @wo and DateCompl is not null and DateCompl <= @wodate
   				while @woitem is not null
   					begin
   					/* work order parts table */
   					delete bEMWP where EMCo = @emco and Equipment = @equip and WorkOrder = @wo and WOItem = @woitem
   					select @woitem = min(WOItem) from EMWI where EMCo = @emco and Equipment = @equip and WorkOrder = @wo and DateCompl is not null and DateCompl <= @wodate and WOItem > @woitem
   					end
   				/* work order items table */
   				delete bEMWI where EMCo = @emco and Equipment = @equip and WorkOrder = @wo and DateCompl is not null and DateCompl <= @wodate
   				/* work order header table */
   				if not exists(select * from EMWI where EMCo = @emco and Equipment = @equip and WorkOrder= @wo)
   					begin
   					delete bEMWH where EMCo = @emco and Equipment = @equip and WorkOrder = @wo
   					end
   				select @wo = min(WorkOrder) from EMWI where EMCo = @emco and Equipment = @equip and DateCompl is not null and DateCompl <= @wodate and WorkOrder > @wo
   				end
   			End
   	
   		/* purge equipment out of meter reading table after potential passes through EMCD and EMRD */
   		if @chkMeter = 'Y'
   			begin
   			select @mth = min(Mth) from EMMR where EMCo = @emco and Equipment = @equip and Mth <= @metermth
   			while @mth is not null
   				begin
   				select @trans = min(EMTrans) from EMMR where EMCo = @emco and Mth = @mth and Equipment = @equip
   				while @trans is not null
   					begin
   					delete bEMMR where EMCo = @emco and Mth = @mth and EMTrans = @trans
   					select @trans = min(EMTrans) from EMMR where EMCo = @emco and Mth = @mth and Equipment = @equip and EMTrans > @trans
   					end
   				select @mth = min(Mth) from EMMR where EMCo = @emco and Equipment = @equip and Mth <= @metermth and Mth > @mth
   				end
   			end
   	
   		select @equip = min(Equipment) from EMEM where EMCo = @emco and Type = 'E' and Category = @catgy and Equipment > @equip
   		End
   	End
   
   /*****************************************/
    
   if @optData = 'T'
   	Begin
   	/* purge equipment out of component history table */
   	if @chkComp = 'Y'
   		begin
   		delete bEMHC where EMCo = @emco and Component = @component and DateXferOff is not null and DateXferOff <= @compdate
   		end

   	/* purge equipment out of revenue detail tables */
   	if @chkRev = 'Y'
   		begin
   		select @mth = min(Mth) from EMRD where EMCo = @emco and Mth <= @revmth and Equipment = @component
   		while @mth is not null
   			begin
   			select @trans = min(Trans)	from EMRD where EMCo = @emco and Mth = @mth and Equipment = @component
   			while @trans is not null
   				begin
   				delete bEMRD where EMCo = @emco and Mth = @mth and Trans = @trans
   				select @trans = min(Trans) from EMRD where EMCo = @emco and Mth = @mth and Equipment = @component and Trans > @trans
   				end
   			select @mth = min(Mth) from EMRD where EMCo = @emco and Equipment = @component and Mth < = @revmth and Mth > @mth
   			end
   		end
   	
   	/* purge equipment out of cost detail table */
   	if @chkCost = 'Y'
   		begin
   		select @mth = min(Mth) from EMCD where EMCo = @emco and Mth <= @costmth and Equipment = @component
   		while @mth is not null
   			begin
   			select @trans = min(EMTrans) from EMCD where EMCo = @emco and Mth = @mth and Equipment = @component
   			while @trans is not null
   				begin
   				delete EMCD where EMCo = @emco and Mth = @mth and EMTrans = @trans
   				select @trans = min(EMTrans) from EMCD where EMCo = @emco and Mth = @mth and Equipment = @component and EMTrans > @trans
   				end
   			select @mth = min(Mth) from EMCD where EMCo = @emco and Equipment = @component and Mth <= @costmth and Mth > @mth
   			end
   		end
   	
   	/* purge equipment out of work order tables */
   	if @chkWO = 'Y'
   		Begin
   		select @wo = min(WorkOrder) from EMWI where EMCo = @emco and Equipment = @component and DateCompl is not null and DateCompl <= @wodate
   		while @wo is not null
   			begin
   			select @woitem = min(WOItem) from EMWI where EMCo = @emco and Equipment = @component and WorkOrder = @wo and DateCompl is not null and DateCompl <= @wodate
   			while @woitem is not null
   				begin
   				/* work order parts table */
   				delete bEMWP where EMCo = @emco and Equipment = @component and WorkOrder = @wo and WOItem = @woitem
   				select @woitem = min(WOItem) from EMWI where EMCo = @emco and Equipment = @component and WorkOrder = @wo and DateCompl is not null and DateCompl <= @wodate and WOItem > @woitem
   				end
   			/* work order items table */
   			delete bEMWI where EMCo = @emco and Equipment = @component and WorkOrder = @wo and DateCompl is not null and DateCompl <= @wodate
   			/* work order header table */
   			if not exists(select * from EMWI where EMCo = @emco and Equipment = @component and WorkOrder= @wo)
   				begin
   				delete bEMWH where EMCo = @emco and Equipment = @component and WorkOrder = @wo
   				end
   			select @wo = min(WorkOrder) from EMWI where EMCo = @emco and Equipment = @component and DateCompl is not null and DateCompl <= @wodate and WorkOrder > @wo
   			end
   		End
   	
   	/* purge equipment out of meter reading table after potential passes through EMCD and EMRD */
   	if @chkMeter = 'Y'
   		begin
   		select @mth = min(Mth) from EMMR where EMCo = @emco and Equipment = @component and Mth <= @metermth
   		while @mth is not null
   			begin
   			select @trans = min(EMTrans) from EMMR where EMCo = @emco and Mth = @mth and Equipment = @component
   			while @trans is not null
   				begin
   				delete bEMMR where EMCo = @emco and Mth = @mth and EMTrans = @trans
   				select @trans = min(EMTrans) from EMMR where EMCo = @emco and Mth = @mth and Equipment = @component and EMTrans > @trans
   				end
   			select @mth = min(Mth) from EMMR where EMCo = @emco and Equipment = @component and Mth <= @metermth and Mth > @mth
   			end
   		end
   	End

/*************************************/
if @optData = 'A'
   	Begin
	---- purge equipment out of component history table
   	if @chkComp = 'Y'
   		begin
   		delete bEMHC where EMCo = @emco and DateXferOff is not null and DateXferOff <= @compdate
   		end

	---- purge equipment out of location history table
   	if @chkLoc = 'Y'
   		begin    
		if isnull(@locdate,'')<> ''
			begin
       		select @mth = min(Month) 
			from EMLH where EMCo = @emco and DateOut is not null and DateOut <= @locdate
       		while @mth is not null
       			begin
       			select @trans = min(Trans) 
				from EMLH where EMCo = @emco and Month = @mth and DateOut is not null and DateOut <= @locdate
       			while @trans is not null
       				begin

       				delete bEMLH where EMCo = @emco and Month = @mth and Trans = @trans

       				select @trans = min(Trans) from EMLH 
					where EMCo = @emco and Month = @mth and DateOut is not null and DateOut <= @locdate and Trans > @trans
       				end
       			select @mth = min(Month) from EMLH 
				where EMCo = @emco and DateOut is not null and DateOut <= @locdate and Month > @mth
				end
			end
		else
			begin
			---- if no location date restriction is provided, delete all records
			delete bEMLH where EMCo = @emco
			 end
		end
   	
   	/* purge equipment out of revenue detail tables */
   	if @chkRev = 'Y'
   		begin
   		select @mth = min(Mth) from EMRD where EMCo = @emco and Mth <= @revmth
   		while @mth is not null
   			begin
   			select @trans = min(Trans) from EMRD where EMCo = @emco and Mth = @mth
   			while @trans is not null
   				begin
   				delete bEMRD where EMCo = @emco and Mth = @mth and Trans = @trans
   				select @trans = min(Trans) from EMRD where EMCo = @emco and Mth = @mth and Trans > @trans
   				end
   			select @mth = min(Mth) from EMRD where EMCo = @emco and Mth < = @revmth and Mth > @mth
   			end
   		end
   	
   	/* purge equipment out of cost detail table */
   	if @chkCost = 'Y'
   		begin
   		select @mth = min(Mth) from EMCD where EMCo = @emco and Mth <= @costmth
   		while @mth is not null
   			begin
   			select @trans = min(EMTrans) from EMCD where EMCo = @emco and Mth = @mth
   			while @trans is not null
   				begin
   				delete EMCD where EMCo = @emco and Mth = @mth and EMTrans = @trans
   				select @trans = min(EMTrans) from EMCD where EMCo = @emco and Mth = @mth and EMTrans > @trans
   				end
   			select @mth = min(Mth) from EMCD 	where EMCo = @emco and Mth <= @costmth and Mth > @mth
   			end
   		end
   	
   	/* purge equipment out of work order tables */
   	if @chkWO = 'Y'
   		Begin
   		select @wo = min(WorkOrder) from EMWI where EMCo = @emco and DateCompl is not null and DateCompl <= @wodate
   		while @wo is not null
   			begin
   			select @woitem = min(WOItem) from EMWI where EMCo = @emco and WorkOrder = @wo and DateCompl is not null and DateCompl <= @wodate
   			while @woitem is not null
   				begin
   				/* work order parts table */
   				delete bEMWP where EMCo = @emco and WorkOrder = @wo and WOItem = @woitem
   				select @woitem = min(WOItem) from EMWI where EMCo = @emco and WorkOrder = @wo and DateCompl is not null and DateCompl <= @wodate and WOItem > @woitem
   				end
   			/* work order items table */
   			delete bEMWI where EMCo = @emco and WorkOrder = @wo and DateCompl is not null and DateCompl <= @wodate
   			/* work order header table */
   			if not exists(select * from EMWI where EMCo = @emco and WorkOrder= @wo)
   				begin
   				delete bEMWH where EMCo = @emco and WorkOrder = @wo
   				end
   			select @wo = min(WorkOrder) from EMWI where EMCo = @emco and DateCompl is not null and DateCompl <= @wodate and WorkOrder > @wo
   			end
   		End
   	
   	/* purge equipment out of meter reading table after potential passes through EMCD and EMRD */
   	if @chkMeter = 'Y'
   		begin
   		select @mth = min(Mth) from EMMR where EMCo = @emco and Mth <= @metermth
   		while @mth is not null
   			begin
   			select @trans = min(EMTrans) from EMMR where EMCo = @emco and Mth = @mth
   			while @trans is not null
   				begin
   				delete bEMMR where EMCo = @emco and Mth = @mth and EMTrans = @trans
   				select @trans = min(EMTrans) from EMMR where EMCo = @emco and Mth = @mth and EMTrans > @trans
   				end
   			select @mth = min(Mth) from EMMR where EMCo = @emco and Mth <= @metermth and Mth > @mth
   			end
   		end
   
   	End
    
   bspexit:
    	if @rcode<>0 select @errmsg=isnull(@errmsg,'')
		else select @errmsg = 'Purge is complete.'

    	return @rcode


GO
GRANT EXECUTE ON  [dbo].[bspEMPurgeHistory] TO [public]
GO
