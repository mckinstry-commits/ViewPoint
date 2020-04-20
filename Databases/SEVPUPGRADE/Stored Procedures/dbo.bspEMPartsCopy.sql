SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   proc [dbo].[bspEMPartsCopy]    
/***********************************************************************
   *        created: TV 03/18/03 
   *
   *
   *        purpose: To copy Parts from an existsing piece of Equipment to
   *                 to another Euipmant, range of Equipment or Catagory
   *
   *        inputs: @emco Company
   *                @mainequip source equipment
   *                @ce Catagory or Equip
   *                @Catagory
   *                @begEquip begining Equip in range. Or single piece of Equip
   *                @endEquip Ending Equip in range. Null if single
   *                @appendreplace Append existing parts, or replace them
   *    
   *        outputs: @errmsg
   *
***********************************************************************/
(@emco bCompany, @mainequip bEquip, @ce char(1), @catagory bCat = null, @begEquip bEquip = null,
 @endEquip bEquip = null, @appendreplace char(1), @errmsg varchar(255)output) 
as     
set nocount on

Declare @rcode int, @clearEquip bEquip, @replaceEquip bEquip

select @rcode = 0

If isnull(@emco,'') = ''
       begin
       select @errmsg = 'EMCo cannot be null.',@rcode = 1
       goto bspexit
       end    

If isnull(@mainequip,'') = ''
       begin
       select @errmsg = 'The From Equipment cannot be null.',@rcode = 1
       goto bspexit
       end

if @ce = 'E'
	begin
	declare bcReplaceParts cursor LOCAL FAST_FORWARD for select Equipment 
	from bEMEM with (nolock)
	where EMCo = @emco and Equipment >= @begEquip and Equipment <= isnull(@endEquip, @begEquip)

	open bcReplaceParts

	fetchnext:
	fetch next from bcReplaceParts into @clearEquip

	if @@Fetch_status <> 0 goto fetchend

	if @appendreplace = 'R'--remove existing parts if @appendreplace = 'R'
		begin   
		delete bEMEP where EMCo = @emco and Equipment = @clearEquip and Equipment <> @mainequip
		end 


	insert bEMEP(EMCo, Equipment, PartNo, Description, MatlGroup, HQMatl, Qty, UM, Notes)
	select EMCo, @clearEquip, PartNo, Description, MatlGroup, HQMatl, Qty, UM, Notes
	from bEMEP where EMCo = @emco and Equipment = @mainequip
	and not exists (select Top 1 1 from bEMEP p where p.EMCo = @emco and p.Equipment = @clearEquip
				and p.PartNo = bEMEP.PartNo) 

	goto fetchnext

	fetchend:        
		close bcReplaceParts
		deallocate bcReplaceParts
		end
	else 
		begin
		declare bcReplacePartsCat cursor LOCAL FAST_FORWARD for select m.Equipment 
		from bEMEM m 
		where m.EMCo = @emco and m.Category = @catagory

		open bcReplacePartsCat

	fetchnextCat:
	fetch next from bcReplacePartsCat into @clearEquip

	if @@Fetch_status <> 0 goto fetchendCat
       
	if @appendreplace = 'R'--remove existing parts if @appendreplace = 'R'
		begin   
		delete bEMEP where EMCo = @emco and Equipment = @clearEquip and Equipment <> @mainequip
		end
   
	insert bEMEP(EMCo, Equipment, PartNo, Description, MatlGroup, HQMatl, Qty, UM, Notes)
	select EMCo, @clearEquip, PartNo, Description, MatlGroup, HQMatl, Qty, UM, Notes
	from bEMEP where EMCo = @emco and Equipment = @mainequip
	and not exists(select Top 1 1 from bEMEP p where p.EMCo = @emco and p.Equipment = @clearEquip
				and p.PartNo = bEMEP.PartNo)

	goto fetchnextCat

	fetchendCat:        
	close bcReplacePartsCat
	deallocate bcReplacePartsCat
	end


bspexit:

GO
GRANT EXECUTE ON  [dbo].[bspEMPartsCopy] TO [public]
GO
