SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE    proc [dbo].[vspEMWOCopyGridFill]
/*************************************************************************
* Created by:	TRL 05/21/2008	-	Issue #128499, Make EM WO Copy look function similar EM WO Init
* Modified by:	TRL 05/29/2009	-	Issue #133459 - reset @allowitems default value to yes ('Y')
*				CHS	03/01/2010	-	issue #138090
*					TRL 03/22/2010 - Issue 135579 removed code determining @allowoitemsfinal
* 
* USAGE:  Copies a WO to a range of Equipment, an equipment Category or an Equip Series (Yr/Make/Model).
* 
* INPUT PARAMS:
*	@emco				Form EMCo
*	@CopyFromWO			WO to copy
*	@CopyToOption			'C' for Category of Equip, 'E' for Equipment Range or 'S' for Equip Series
*	@CopyToCategory		EMEM.Category of Equipment that WO is to be copied to for @CopyToOption = 'C'
*	@CopyToBegEquip		Beginning of range of EMEM.Equipment that WO is to be copied to for @CopyToOption = 'E'
*	@CopyToEndEquip		Ending of range of EMEM.Equipment that WO is to be copied to for @CopyToOption = 'E'
*	@copytoequipseriesyear	EMEM.ModelYr that WO is to be copied to for @CopyToOption = 'S'
*	@CopyToEquipSeriesMake	EMEM.Manufacturer that WO is to be copied to for @CopyToOption = 'S'
*	@copytoequipseriesmodel	EMEM.Model that WO is to be copied to for @CopyToOption = 'S'
*	@ShopOption			W for Copy From WO Shop, E for Copy To Equip Shop, S for Specified Shop
*	@Shop				From: Copy From WO Shop or Specified Shop; will be null if Copy To Equip Shop since
*					it will need to be selected in loop per CopyToEquip
* 
* OUTPUT PARAMS:
*	@rcode		Return code; 0 = success, 1 = failure
*	@ErrMsg		Error message; # copied if success, error message if failure
*************************************************************************/
(@emco bCompany = null,@copyfromWO bWO = null,@copytooption char(1) = null,@copytocategory bCat = null,
@copytobegequip bEquip = null,@copytoendequip bEquip = null,@copytoequipseriesyear varchar(6) = null,
@copytoequipseriesmfr varchar(20) = null,@copytoequipseriesmodel varchar(20) = null,@errmsg varchar(255) output)
 
As 
 
Set nocount on 
 
-- Initialize general local variables. 
declare @rcode int,@copyfromWOequip bEquip,@copyfromWOshop varchar(20),@allwoitemsfinal varchar(1),@wocomplete varchar(1)
 
select @rcode = 0,@allwoitemsfinal='Y'
 
-- Verify necessary parameters passed. 
if @emco is null
begin
 	select @errmsg = 'Missing EM Company!', @rcode = 1
	goto vspexit
end
 
if IsNull(@copyfromWO,'')= ''
begin
 	select @errmsg = 'Missing Copy From Work Order!', @rcode = 1
 	goto vspexit
end
 
if IsNull(@copytooption,'')=''
begin
	select @errmsg = 'Missing Copy To Option!', @rcode = 1
 	goto vspexit
end

-- Get Equipment for CopyFromWO so that it can be excluded from any range 
select @copyfromWOequip = Equipment,@copyfromWOshop=Shop,@wocomplete=IsNull(Complete,'N')
from dbo.EMWH with(nolock)
where EMCo = @emco and WorkOrder = @copyfromWO
If @@rowcount = 0
begin
	select @errmsg = 'Copy From Work Order doesnot exist!', @rcode = 1
end

/*135579*/
--If @wocomplete='Y'
--begin
	If exists(select top 1 1 from dbo.EMWI i with(nolock) 
	Left Join EMWS s with(nolock)on s.EMGroup =i.EMGroup and s.StatusCode=i.StatusCode
	Where EMCo=@emco  and WorkOrder=@copyfromWO and IsNull(s.StatusType,'') <> 'F')
	begin
		select @allwoitemsfinal = 'N'
	end
--end

create table #SelectedEquipToCopy
(Equipment varchar(10),EquipDesc varchar(60),Copy varchar(1),Copied varchar(1),Results varchar(60),
 ModelYr varchar(6),Manufacturer varchar(20),Model varchar(20),Category varchar(10),CategoryDesc varchar(60),
 Shop varchar(20),ShopDesc varchar(60))


--Select Equipment Range to copy
--Category
if @copytooption = 'C'
begin
    Insert Into #SelectedEquipToCopy (Equipment,EquipDesc,Copy,Copied,Results,ModelYr,Manufacturer,Model,
	Category,CategoryDesc,Shop,ShopDesc)
	select m.Equipment,EquipDesc=m.Description,Copy='Y',Copied='N',Results='',m.ModelYr,m.Manufacturer,m.Model,
	m.Category,CategoryDesc=c.Description,m.Shop,ShopDesc=s.Description
	from dbo.EMEM m with(nolock)
	left Join dbo.EMCM c with(nolock)on c.EMCo=m.EMCo and c.Category=m.Category
	left Join dbo.EMSX s with(nolock)on s.ShopGroup=m.ShopGroup and s.Shop=m.Shop
	where m.EMCo = @emco and c.Category = @copytocategory and Equipment <> @copyfromWOequip 
	and  @copytobegequip >=  @copyfromWOequip and @copyfromWOequip <= @copytoendequip
	and Status <> 'I' and Type <> 'C' 
 	order by Equipment

	If @allwoitemsfinal = 'Y'
	begin
	    Insert Into #SelectedEquipToCopy (Equipment,EquipDesc,Copy,Copied,Results,ModelYr,Manufacturer,Model,
		Category,CategoryDesc,Shop,ShopDesc)
		select m.Equipment,EquipDesc=m.Description,Copy='Y',Copied='N',Results='All Source WO Items are Final',m.ModelYr,m.Manufacturer,m.Model,
		m.Category,CategoryDesc=c.Description,m.Shop,ShopDesc=s.Description
		from dbo.EMEM m with(nolock)
		left Join dbo.EMCM c with(nolock)on c.EMCo=m.EMCo and c.Category=m.Category
		left Join dbo.EMSX s with(nolock)on s.ShopGroup=m.ShopGroup and s.Shop=m.Shop
		where m.EMCo = @emco and c.Category = @copytocategory and Equipment = @copyfromWOequip 
		-- issue #138090
		and  @copyfromWOequip >= @copytobegequip and @copyfromWOequip <= @copytoendequip
		and Status <> 'I' and Type <> 'C' 
	end

end
--Range of Equipment
if @copytooption = 'E'
begin
	Insert Into #SelectedEquipToCopy (Equipment,EquipDesc,Copy,Copied,Results,ModelYr,Manufacturer,Model,
	Category,CategoryDesc,Shop,ShopDesc)
 	select m.Equipment,EquipDesc=m.Description,Copy='Y',Copied='N',Results='',m.ModelYr,m.Manufacturer,m.Model,
	m.Category,CategoryDesc=c.Description,m.Shop,ShopDesc=s.Description
	from dbo.EMEM m with(nolock)
	left Join dbo.EMCM c with(nolock)on c.EMCo=m.EMCo and c.Category=m.Category
	left Join dbo.EMSX s with(nolock)on s.ShopGroup=m.ShopGroup and s.Shop=m.Shop
 	where m.EMCo = @emco and  Equipment >= @copytobegequip and Equipment <= @copytoendequip
 	and Equipment <> @copyfromWOequip and Status <> 'I' and Type <> 'C' 
 	
	If @allwoitemsfinal = 'Y'
	begin
		Insert Into #SelectedEquipToCopy (Equipment,EquipDesc,Copy,Copied,Results,ModelYr,Manufacturer,Model,
		Category,CategoryDesc,Shop,ShopDesc)
		select m.Equipment,EquipDesc=m.Description,Copy='Y',Copied='N',Results='All Source WO Items are Final',m.ModelYr,m.Manufacturer,m.Model,
		m.Category,CategoryDesc=c.Description,m.Shop,ShopDesc=s.Description
		from dbo.EMEM m with(nolock)
		left Join dbo.EMCM c with(nolock)on c.EMCo=m.EMCo and c.Category=m.Category
		left Join dbo.EMSX s with(nolock)on s.ShopGroup=m.ShopGroup and s.Shop=m.Shop
 		where m.EMCo = @emco and Equipment= @copyfromWOequip 
 		-- issue #138090
 		 and  @copyfromWOequip >= @copytobegequip and @copyfromWOequip <= @copytoendequip
 		and Status <> 'I' and Type <> 'C' 
 	end
end
 
if @copytooption = 'S' --Equipment Series
Begin
 	-- Convert @copytoequipseriesmfr and @copytoequipseriesmodel to lower case to match any cases in table 
 	select @copytoequipseriesmfr = lower(@copytoequipseriesmfr), @copytoequipseriesmodel= lower(@copytoequipseriesmodel)
 	
 	-- Year, Mfr and Model 
 	if IsNull(@copytoequipseriesyear,'')<>'' and IsNull(@copytoequipseriesmfr,'')<>'' and IsNull(@copytoequipseriesmodel,'')<>''
	begin
		Insert Into #SelectedEquipToCopy (Equipment,EquipDesc,Copy,Copied,Results,ModelYr,Manufacturer,Model,
		Category,CategoryDesc,Shop,ShopDesc)
 		select m.Equipment,EquipDesc=m.Description,Copy='Y',Copied='N',Results='',m.ModelYr,m.Manufacturer,m.Model,
		m.Category,CategoryDesc=c.Description,m.Shop,ShopDesc=s.Description
		from dbo.EMEM m with(nolock)
		left Join dbo.EMCM c with(nolock)on c.EMCo=m.EMCo and c.Category=m.Category
		left Join dbo.EMSX s with(nolock)on s.ShopGroup=m.ShopGroup and s.Shop=m.Shop
 		where m.EMCo = @emco and Equipment <> @copyfromWOequip and Status <> 'I' and Type <> 'C' 
 		and ModelYr = @copytoequipseriesyear and lower(Manufacturer) = @copytoequipseriesmfr 
 		and lower(Model) = @copytoequipseriesmodel

	 	If @allwoitemsfinal = 'Y'
		begin
			Insert Into #SelectedEquipToCopy (Equipment,EquipDesc,Copy,Copied,Results,ModelYr,Manufacturer,Model,
			Category,CategoryDesc,Shop,ShopDesc)
 			select m.Equipment,EquipDesc=m.Description,Copy='Y',Copied='N',Results='All Source WO Items are Final',m.ModelYr,m.Manufacturer,m.Model,
			m.Category,CategoryDesc=c.Description,m.Shop,ShopDesc=s.Description
			from dbo.EMEM m with(nolock)
			left Join dbo.EMCM c with(nolock)on c.EMCo=m.EMCo and c.Category=m.Category
			left Join dbo.EMSX s with(nolock)on s.ShopGroup=m.ShopGroup and s.Shop=m.Shop
 			where m.EMCo = @emco and Equipment = @copyfromWOequip and Status <> 'I' and Type <> 'C' 
 			and ModelYr = @copytoequipseriesyear and lower(Manufacturer) = @copytoequipseriesmfr 
 			and lower(Model) = @copytoequipseriesmodel
 			-- issue #138090
 			and  @copyfromWOequip >= @copytoendequip and @copyfromWOequip <= @copytoendequip
 		end
 	end

 	-- Year only 
 	if IsNull(@copytoequipseriesyear,'')<>'' and IsNull(@copytoequipseriesmfr,'')='' and IsNull(@copytoequipseriesmodel,'')=''
 	begin
		Insert Into #SelectedEquipToCopy (Equipment,EquipDesc,Copy,Copied,Results,ModelYr,Manufacturer,Model,
		Category,CategoryDesc,Shop,ShopDesc)
 		select m.Equipment,EquipDesc=m.Description,Copy='Y',Copied='N',Results='',m.ModelYr,m.Manufacturer,m.Model,
		m.Category,CategoryDesc=c.Description,m.Shop,ShopDesc=s.Description
		from dbo.EMEM m with(nolock)
		left Join dbo.EMCM c with(nolock)on c.EMCo=m.EMCo and c.Category=m.Category
		left Join dbo.EMSX s with(nolock)on s.ShopGroup=m.ShopGroup and s.Shop=m.Shop
 		where m.EMCo = @emco and Equipment <> @copyfromWOequip and Status <> 'I' and Type <> 'C' 
 		and ModelYr = @copytoequipseriesyear 
 		
		If @allwoitemsfinal = 'Y'
		begin
			Insert Into #SelectedEquipToCopy (Equipment,EquipDesc,Copy,Copied,Results,ModelYr,Manufacturer,Model,
			Category,CategoryDesc,Shop,ShopDesc)
			select m.Equipment,EquipDesc=m.Description,Copy='Y',Copied='N',Results='All Source WO Items are Final',m.ModelYr,m.Manufacturer,m.Model,
			m.Category,CategoryDesc=c.Description,m.Shop,ShopDesc=s.Description
			from dbo.EMEM m with(nolock)
			left Join dbo.EMCM c with(nolock)on c.EMCo=m.EMCo and c.Category=m.Category
			left Join dbo.EMSX s with(nolock)on s.ShopGroup=m.ShopGroup and s.Shop=m.Shop
 			where m.EMCo = @emco and Equipment = @copyfromWOequip and Status <> 'I' and Type <> 'C' 
 			and ModelYr = @copytoequipseriesyear 
 			-- issue #138090
 			and  @copyfromWOequip >= @copytoendequip and @copyfromWOequip <= @copytoendequip
		end
 	end
 	
 	-- Mfr only 
 	if IsNull(@copytoequipseriesyear,'')=''and IsNull(@copytoequipseriesmfr,'')<>'' and  IsNull(@copytoequipseriesmodel,'')=''
 	begin
		Insert Into #SelectedEquipToCopy (Equipment,EquipDesc,Copy,Copied,Results,ModelYr,Manufacturer,Model,
		Category,CategoryDesc,Shop,ShopDesc)
 		select m.Equipment,EquipDesc=m.Description,Copy='Y',Copied='N',Results='',m.ModelYr,m.Manufacturer,m.Model,
		m.Category,CategoryDesc=c.Description,m.Shop,ShopDesc=s.Description
		from dbo.EMEM m with(nolock)
		left Join dbo.EMCM c with(nolock)on c.EMCo=m.EMCo and c.Category=m.Category
		left Join dbo.EMSX s with(nolock)on s.ShopGroup=m.ShopGroup and s.Shop=m.Shop
 		where m.EMCo = @emco and Equipment <> @copyfromWOequip and Status <> 'I' and Type <> 'C' 
 		and lower(Manufacturer) = @copytoequipseriesmfr 
 		 		
		If @allwoitemsfinal = 'Y'
		begin
			Insert Into #SelectedEquipToCopy (Equipment,EquipDesc,Copy,Copied,Results,ModelYr,Manufacturer,Model,
			Category,CategoryDesc,Shop,ShopDesc)
	 		select m.Equipment,EquipDesc=m.Description,Copy='Y',Copied='N',Results='All Source WO Items are Final',m.ModelYr,m.Manufacturer,m.Model,
			m.Category,CategoryDesc=c.Description,m.Shop,ShopDesc=s.Description
			from dbo.EMEM m with(nolock)
			left Join dbo.EMCM c with(nolock)on c.EMCo=m.EMCo and c.Category=m.Category
			left Join dbo.EMSX s with(nolock)on s.ShopGroup=m.ShopGroup and s.Shop=m.Shop
 			where m.EMCo = @emco and Equipment = @copyfromWOequip and Status <> 'I' and Type <> 'C' 
 			and lower(Manufacturer) = @copytoequipseriesmfr 
 			-- issue #138090
 			and  @copyfromWOequip >= @copytoendequip and @copyfromWOequip <= @copytoendequip
		end
 	end
 	
 	-- Model only 
 	if IsNull(@copytoequipseriesyear,'')='' and IsNull(@copytoequipseriesmfr,'')='' and IsNull(@copytoequipseriesmodel,'')<> ''
 	begin
		Insert Into #SelectedEquipToCopy (Equipment,EquipDesc,Copy,Copied,Results,ModelYr,Manufacturer,Model,
		Category,CategoryDesc,Shop,ShopDesc)
 		select m.Equipment,EquipDesc=m.Description,Copy='Y',Copied='N',Results='',m.ModelYr,m.Manufacturer,m.Model,
		m.Category,CategoryDesc=c.Description,m.Shop,ShopDesc=s.Description
		from dbo.EMEM m with(nolock)
		left Join dbo.EMCM c with(nolock)on c.EMCo=m.EMCo and c.Category=m.Category
		left Join dbo.EMSX s with(nolock)on s.ShopGroup=m.ShopGroup and s.Shop=m.Shop
 		where m.EMCo = @emco and Equipment <> @copyfromWOequip and Status <> 'I' and Type <> 'C' 
 		and lower(Model) = @copytoequipseriesmodel

		If @allwoitemsfinal = 'Y'
		begin
			Insert Into #SelectedEquipToCopy (Equipment,EquipDesc,Copy,Copied,Results,ModelYr,Manufacturer,Model,
			Category,CategoryDesc,Shop,ShopDesc)
 			select m.Equipment,EquipDesc=m.Description,Copy='Y',Copied='N',Results='All Source WO Items are Final',m.ModelYr,m.Manufacturer,m.Model,
			m.Category,CategoryDesc=c.Description,m.Shop,ShopDesc=s.Description
			from dbo.EMEM m with(nolock)
			left Join dbo.EMCM c with(nolock)on c.EMCo=m.EMCo and c.Category=m.Category
			left Join dbo.EMSX s with(nolock)on s.ShopGroup=m.ShopGroup and s.Shop=m.Shop
 			where m.EMCo = @emco and Equipment = @copyfromWOequip and Status <> 'I' and Type <> 'C' 
 			and lower(Model) = @copytoequipseriesmodel
 			-- issue #138090
 			and  @copyfromWOequip >= @copytoendequip and @copyfromWOequip <= @copytoendequip
		end
 	end
 	
 	-- Year and Mfr 
 	if IsNull(@copytoequipseriesyear,'')<>''and IsNull(@copytoequipseriesmfr,'')<>'' and  IsNull(@copytoequipseriesmodel,'')=''
 	begin
		Insert Into #SelectedEquipToCopy (Equipment,EquipDesc,Copy,Copied,Results,ModelYr,Manufacturer,Model,
		Category,CategoryDesc,Shop,ShopDesc)
 		select m.Equipment,EquipDesc=m.Description,Copy='Y',Copied='N',Results='',m.ModelYr,m.Manufacturer,m.Model,
		m.Category,CategoryDesc=c.Description,m.Shop,ShopDesc=s.Description
		from dbo.EMEM m with(nolock)
		left Join dbo.EMCM c with(nolock)on c.EMCo=m.EMCo and c.Category=m.Category
		left Join dbo.EMSX s with(nolock)on s.ShopGroup=m.ShopGroup and s.Shop=m.Shop
 		where m.EMCo = @emco and Equipment <> @copyfromWOequip and Status <> 'I' and Type <> 'C' 
 		and ModelYr = @copytoequipseriesyear and lower(Manufacturer) = @copytoequipseriesmfr 
 	
		If @allwoitemsfinal = 'Y'
		begin
			Insert Into #SelectedEquipToCopy (Equipment,EquipDesc,Copy,Copied,Results,ModelYr,Manufacturer,Model,
			Category,CategoryDesc,Shop,ShopDesc)
	 		select m.Equipment,EquipDesc=m.Description,Copy='Y',Copied='N',Results='All Source From WO Items are Final',m.ModelYr,m.Manufacturer,m.Model,
			m.Category,CategoryDesc=c.Description,m.Shop,ShopDesc=s.Description
			from dbo.EMEM m with(nolock)
			left Join dbo.EMCM c with(nolock)on c.EMCo=m.EMCo and c.Category=m.Category
			left Join dbo.EMSX s with(nolock)on s.ShopGroup=m.ShopGroup and s.Shop=m.Shop
 			where m.EMCo = @emco and Equipment = @copyfromWOequip and Status <> 'I' and Type <> 'C' 
 			and ModelYr = @copytoequipseriesyear and lower(Manufacturer) = @copytoequipseriesmfr 
 			-- issue #138090
 			and  @copyfromWOequip >= @copytoendequip and @copyfromWOequip <= @copytoendequip
		end
 	end
 	
 	-- Year and Model
 	if IsNull(@copytoequipseriesyear,'')<>'' and IsNull(@copytoequipseriesmfr,'')='' and IsNull(@copytoequipseriesmodel,'')<>''
 	begin
		Insert Into #SelectedEquipToCopy (Equipment,EquipDesc,Copy,Copied,Results,ModelYr,Manufacturer,Model,
		Category,CategoryDesc,Shop,ShopDesc)
 		select m.Equipment,EquipDesc=m.Description,Copy='Y',Copied='N',Results='',m.ModelYr,m.Manufacturer,m.Model,
		m.Category,CategoryDesc=c.Description,m.Shop,ShopDesc=s.Description
		from dbo.EMEM m with(nolock)
		left Join dbo.EMCM c with(nolock)on c.EMCo=m.EMCo and c.Category=m.Category
		left Join dbo.EMSX s with(nolock)on s.ShopGroup=m.ShopGroup and s.Shop=m.Shop
 		where m.EMCo = @emco and Equipment <> @copyfromWOequip and Status <> 'I' and Type <> 'C'
 		and ModelYr = @copytoequipseriesyear and lower(Model) = @copytoequipseriesmodel
 		
		If @allwoitemsfinal = 'Y'
		begin
			Insert Into #SelectedEquipToCopy (Equipment,EquipDesc,Copy,Copied,Results,ModelYr,Manufacturer,Model,
			Category,CategoryDesc,Shop,ShopDesc)
 			select m.Equipment,EquipDesc=m.Description,Copy='Y',Copied='N',Results='All Source From WO Items are Final',m.ModelYr,m.Manufacturer,m.Model,
			m.Category,CategoryDesc=c.Description,m.Shop,ShopDesc=s.Description
			from dbo.EMEM m with(nolock)
			left Join dbo.EMCM c with(nolock)on c.EMCo=m.EMCo and c.Category=m.Category
			left Join dbo.EMSX s with(nolock)on s.ShopGroup=m.ShopGroup and s.Shop=m.Shop
 			where m.EMCo = @emco and Equipment = @copyfromWOequip and Status <> 'I' and Type <> 'C'
 			and ModelYr = @copytoequipseriesyear and lower(Model) = @copytoequipseriesmodel
 			-- issue #138090
 			and  @copyfromWOequip >= @copytoendequip and @copyfromWOequip <= @copytoendequip
		end
 	end
 	
 	-- Mfr and Model 
 	if IsNull(@copytoequipseriesyear,'')='' and IsNull(@copytoequipseriesmfr,'')<>'' and  IsNull(@copytoequipseriesmodel,'')<>''
	begin
		Insert Into #SelectedEquipToCopy (Equipment,EquipDesc,Copy,Copied,Results,ModelYr,Manufacturer,Model,
		Category,CategoryDesc,Shop,ShopDesc)
 		select m.Equipment,EquipDesc=m.Description,Copy='Y',Copied='N',Results='',m.ModelYr,m.Manufacturer,m.Model,
		m.Category,CategoryDesc=c.Description,m.Shop,ShopDesc=s.Description
		from dbo.EMEM m with(nolock)
		left Join dbo.EMCM c with(nolock)on c.EMCo=m.EMCo and c.Category=m.Category
		left Join dbo.EMSX s with(nolock)on s.ShopGroup=m.ShopGroup and s.Shop=m.Shop
 		where m.EMCo = @emco and Equipment <> @copyfromWOequip and Status <> 'I' and Type <> 'C' 
 		and lower(Manufacturer) = @copytoequipseriesmfr and lower(Model) = @copytoequipseriesmodel

 		If @allwoitemsfinal = 'Y'
		begin
			Insert Into #SelectedEquipToCopy (Equipment,EquipDesc,Copy,Copied,Results,ModelYr,Manufacturer,Model,
			Category,CategoryDesc,Shop,ShopDesc)
			select m.Equipment,EquipDesc=m.Description,Copy='Y',Copied='N',Results='All Source WO Items are Final',m.ModelYr,m.Manufacturer,m.Model,
			m.Category,CategoryDesc=c.Description,m.Shop,ShopDesc=s.Description
			from dbo.EMEM m with(nolock)
			left Join dbo.EMCM c with(nolock)on c.EMCo=m.EMCo and c.Category=m.Category
			left Join dbo.EMSX s with(nolock)on s.ShopGroup=m.ShopGroup and s.Shop=m.Shop
 			where m.EMCo = @emco and Equipment = @copyfromWOequip and Status <> 'I' and Type <> 'C' 
 			and lower(Manufacturer) = @copytoequipseriesmfr and lower(Model) = @copytoequipseriesmodel
 			-- issue #138090
 			and  @copyfromWOequip >= @copytoendequip and @copyfromWOequip <= @copytoendequip
		end
	end
END

select * From #SelectedEquipToCopy Order By Equipment
vspexit:

return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspEMWOCopyGridFill] TO [public]
GO
