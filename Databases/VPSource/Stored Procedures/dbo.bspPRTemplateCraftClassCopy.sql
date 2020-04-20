SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE        procedure [dbo].[bspPRTemplateCraftClassCopy]
     /************************************************************************
     * CREATED: mh 8/6/2004    
     * MODIFIED: mh 10/12/2004 - #25740 Added JobCraft to PRCT insert.
     *
     * Purpose of Stored Procedure
     *
     *    Copies an all or part of an existing Template to a new Template.
     *    
     *           
     * Notes about Stored Procedure
     * 
     *	@prco - Payroll Company
     *	@sourcetemplate - Template to copy from.
     *	@whatcrafts - Flag to determine if "all" or a "single" craft is copied.
     *	@sourcecraft - Source Craft
     *	@payrateyn - Include Pay Rates
     *	@addonearnyn - Include Add On Earnings
     *	@variableearnyn - Include Variable Earnings
     *	@dedliabyn - Include Deduction/Liabilities
     *	@jcitemsyn - Include Job Craft items
     *	@notesyn - Include Notes
     *	@desttemplate - Destination Template    
     *
     *
     * returns 0 if successfull 
     * returns 1 and error msg if failed
     *
     *************************************************************************/
     
         (@prco bCompany, @sourcetemplate smallint, @whatcrafts char(1), @sourcecraft bCraft, 
     	@payrateyn bYN = 'N', @addonearnyn bYN = 'N', @variableearnyn bYN = 'N', @dedliabyn bYN = 'N', 
     	@jcitemsyn bYN = 'Y', @notesyn bYN = 'N', @desttemplate smallint, 
     	@msg varchar(100) = '' output)
     
     as
     set nocount on
     
         declare @rcode int
     
         select @rcode = 0
     
     --All Crafts
     	if @whatcrafts = 'A'
     	begin
     
     		begin transaction
     	
     		--Craft Info - Header
     		Insert dbo.PRCT (PRCo, Craft, Template, OverEffectDate, EffectiveDate, OverOT, OTSched, RecipOpt,
   		JobCraft)
     		(select s.PRCo, s.Craft, @desttemplate, s.OverEffectDate, s.EffectiveDate, s.OverOT, s.OTSched, s.RecipOpt,
   		s.JobCraft
     		from dbo.PRCT s with (nolock) where s.PRCo = @prco and s.Template = @sourcetemplate
     		and not exists (select 1 from dbo.PRCT d with (nolock) where s.PRCo = d.PRCo and s.Craft = d.Craft and d.PRCo = @prco and d.Template = @desttemplate))
     		if @@error = 1
     		begin 
     			select @msg = 'Error copying Craft Template', @rcode = 1
     			rollback transaction
     			goto bspexit
     		end
     	
     		if @notesyn = 'Y'
     		begin
     			update d
     			set d.Notes = s.Notes
     			from dbo.PRCT d with (nolock) join dbo.PRCT s with (nolock) on 
     			d.PRCo = s.PRCo and d.Craft = s.Craft
     			where d.PRCo = @prco and d.Template = @desttemplate and s.Template = @sourcetemplate
     	
     			if @@error = 1
     			begin 
     				select @msg = 'Error copying Craft Template Notes', @rcode = 1
     				rollback transaction
     				goto bspexit
     			end
     		end
     	
     		--Craft Info - Grids. 
     		if @addonearnyn = 'Y'
     		begin
     			insert dbo.PRTI (PRCo, Craft, Template, EDLType, EDLCode, Factor,
     				OldRate, NewRate, UniqueAttchID)
     			(select s.PRCo, s.Craft, @desttemplate, s.EDLType, s.EDLCode, s.Factor, 
     			s.OldRate, s.NewRate, s.UniqueAttchID 
     			from dbo.PRTI s with (nolock) join dbo.PREC e with (nolock) on 
     			s.PRCo = e.PRCo and s.EDLCode = e.EarnCode
     			where s.PRCo = @prco and s.Template = @sourcetemplate and s.EDLType = 'E'
     			and not exists (select 1 from dbo.PRTI d with (nolock) where s.PRCo = d.PRCo and 
     			s.Craft = d.Craft and s.EDLType = d.EDLType and s.EDLCode = d.EDLCode 
     			and d.PRCo = @prco and d.EDLType = 'E' and 
     			d.Template = @desttemplate))
     
     			if @@error = 1
     			begin 
     				select @msg = 'Error copying Craft Template Add-on Earnings', @rcode = 1
     				rollback transaction
     				goto bspexit
     			end
     		end
     	
     		if @dedliabyn = 'Y'
     		begin
     			insert dbo.PRTI (PRCo, Craft, Template, EDLType, EDLCode, Factor,
     				OldRate, NewRate, UniqueAttchID)
 
     			(select s.PRCo, s.Craft, @desttemplate, s.EDLType, s.EDLCode, s.Factor, 
     			s.OldRate, s.NewRate, s.UniqueAttchID 
     			from dbo.PRTI s with (nolock) join dbo.PRDL l with (nolock) on 
     			s.PRCo = l.PRCo and s.EDLCode = l.DLCode and s.EDLType = l.DLType 
     			where s.PRCo = @prco and s.Template = @sourcetemplate and s.EDLType in ('D', 'L')
     			and not exists (select 1 from dbo.PRTI d with (nolock) where s.PRCo = d.PRCo and 
     			s.Craft = d.Craft and s.EDLType = d.EDLType and s.EDLCode = d.EDLCode 
     			and d.PRCo = @prco and (d.EDLType = 'D' or EDLType = 'L') and 
     			d.Template = @desttemplate))
     	
     			if @@error = 1
     			begin 
     				select @msg = 'Error copying Craft Template Deduction/Liability codes', @rcode = 1
     				rollback transaction
     				goto bspexit
     			end
     		end
     	
     		if @jcitemsyn = 'Y'
     		begin
     			insert dbo.PRTR (PRCo, Craft, Template, DLCode, UniqueAttchID)
     			(select s.PRCo, s.Craft, @desttemplate, s.DLCode, s.UniqueAttchID 
     			from dbo.PRTR s with (nolock) join dbo.PRDL l with (nolock) on 
     			s.PRCo = l.PRCo and s.DLCode = l.DLCode
     			where s.PRCo = @prco and s.Template = @sourcetemplate and
     			l.DLType in ('D', 'L')
     			and not exists (select 1 from dbo.PRTR d with (nolock) where s.PRCo = d.PRCo and 
     			s.Craft = d.Craft and s.DLCode = d.DLCode 
     			and d.PRCo = @prco and d.Template = @desttemplate))
     	
     			if @@error = 1
     			begin 
     				select @msg = 'Error copying Craft Template Job Craft Item codes', @rcode = 1
     				rollback transaction
     				goto bspexit
     			end
     		end
     	
     		--Now copy the Craft/Class Template info for this Craft.  Only copying over those entries
     		--that do not currently exist in the destination template.
     		--Craft Header
     		insert dbo.PRTC (PRCo, Craft, Class, Template, OverCapLimit, OldCapLimit, NewCapLimit)
     		(select s.PRCo, s.Craft, s.Class, @desttemplate, s.OverCapLimit, s.OldCapLimit, s.NewCapLimit
     		from dbo.PRTC s with (nolock) 
     		where s.PRCo = @prco and Template = @sourcetemplate 
     		and not exists (select 1 from dbo.PRTC d with (nolock) where s.PRCo = d.PRCo and s.Craft = d.Craft 
     		and s.Class = d.Class and d.PRCo = @prco and d.Template = @desttemplate))
     	
     		if @@error = 1
     		begin 
     			select @msg = 'Error copying Craft Class Template', @rcode = 1
     			rollback transaction
     			goto bspexit
     		end
     	
     		if @notesyn = 'Y'  --need to test this
     		begin
     			update d
     			set d.Notes = s.Notes
     			from dbo.PRTC d with (nolock) join dbo.PRTC s with (nolock) on 
     			d.PRCo = s.PRCo and d.Craft = s.Craft and d.Class = s.Class
     			where d.PRCo = @prco and d.Template = @desttemplate and s.Template = @sourcetemplate and
     			s.Class = d.Class
     	
     			if @@error = 1
     			begin 
     				select @msg = 'Error copying Craft Template Notes', @rcode = 1
     				rollback transaction
     				goto bspexit
     			end
     		end
     
     		--Craft/Class Items	
     		--Copy Pay Rates
     		if @payrateyn = 'Y'
     		begin
     			insert dbo.PRTP (PRCo, Craft, Class, Template, Shift, OldRate, NewRate, UniqueAttchID)
     			(select p.PRCo, p.Craft, p.Class, @desttemplate, p.Shift, p.OldRate, p.NewRate, p.UniqueAttchID
     			from PRTP p with (nolock)
     			where p.PRCo = @prco and Template = @sourcetemplate
     			and not exists (select 1 from dbo.PRTP d with (nolock) where p.PRCo = d.PRCo and p.Craft = d.Craft and 
     			p.Class = d.Class and p.Shift = d.Shift and d.PRCo = @prco and d.Template = @desttemplate))
     	
     			if @@error = 1
     			begin 
     				select @msg = 'Error copying Craft Class Template Pay Rate codes', @rcode = 1
     				rollback transaction
     				goto bspexit
     			end
     		end
     
     		if @variableearnyn = 'Y'
     		begin
     			insert dbo.PRTE (PRCo, Craft, Class, Template, Shift, EarnCode, OldRate, NewRate, UniqueAttchID)
     			(select p.PRCo, p.Craft, p.Class, @desttemplate, p.Shift, p.EarnCode, p.OldRate, p.NewRate, p.UniqueAttchID
     			from dbo.PRTE p with (nolock) join dbo.PREC e with (nolock) on
     			p.PRCo = e.PRCo and p.EarnCode = e.EarnCode
     			where p.PRCo = @prco and Template = @sourcetemplate
     			and not exists (select 1 from dbo.PRTE d with (nolock) where p.PRCo = d.PRCo and p.Craft = d.Craft and 
     			p.Class = d.Class and p.Shift = d.Shift and p.EarnCode = d.EarnCode and d.PRCo = @prco and d.Template = @desttemplate))
     	
     			if @@error = 1
     			begin 
     				select @msg = 'Error copying Craft Class Template Variable Earnings codes', @rcode = 1
     				rollback transaction
     				goto bspexit
     			end
     		end
     
     		if @addonearnyn = 'Y'
     		begin
     			insert dbo.PRTF (PRCo, Craft, Class, Template, EarnCode, Factor, OldRate, NewRate, UniqueAttchID)
     			(select p.PRCo, p.Craft, p.Class, @desttemplate, p.EarnCode, p.Factor, p.OldRate, p.NewRate, p.UniqueAttchID
     			from dbo.PRTF p with (nolock) join dbo.PREC e with (nolock) on
     			p.PRCo = e.PRCo and p.EarnCode = e.EarnCode
     			where p.PRCo = @prco and Template = @sourcetemplate
     			and not exists (select 1 from dbo.PRTF d with (nolock) where p.PRCo = d.PRCo and p.Craft = d.Craft and 
     			p.Class = d.Class and p.EarnCode = d.EarnCode and p.Factor = d.Factor and d.PRCo = @prco and d.Template = @desttemplate))
     	
     			if @@error = 1
     			begin 
     				select @msg = 'Error copying Craft Class Template Add-on Earnings codes', @rcode = 1
     				rollback transaction
     				goto bspexit
     			end
     		end
     
     		if @dedliabyn = 'Y'
     		begin
     			insert dbo.PRTD (PRCo, Craft, Class, Template, DLCode, Factor, OldRate, NewRate, UniqueAttchID)
     			(select p.PRCo, p.Craft, p.Class, @desttemplate, p.DLCode, p.Factor, p.OldRate, p.NewRate, p.UniqueAttchID
     			from dbo.PRTD p with (nolock) join dbo.PRDL l with (nolock) on 
     			p.PRCo = l.PRCo and p.DLCode = l.DLCode  
     			where p.PRCo = @prco and p.Template = @sourcetemplate 
     			and not exists (select 1 from dbo.PRTD d with (nolock) where p.PRCo = d.PRCo and p.Craft = d.Craft and 
     			p.Class = d.Class and p.DLCode = d.DLCode and p.Factor = d.Factor and d.PRCo = @prco and d.Template = @desttemplate))
     	
     			if @@error = 1
     			begin 
     				select @msg = 'Error copying Craft Class Template Pay Rate codes', @rcode = 1
     				rollback transaction
     				goto bspexit
     			end
     		end
     
     		commit transaction
     
     	end
     
     --Selected Craft
     	if @whatcrafts = 'S'
     	begin
     
     		begin transaction
     	
     		--Craft Info - Header
     		if not exists(select PRCo from dbo.PRCT with (nolock) where PRCo = @prco and Craft = @sourcecraft
     						and Template = @desttemplate)
     		begin --If Craft already exists in destination template do not copy over.
     			Insert dbo.PRCT (PRCo, Craft, Template, OverEffectDate, 
     				EffectiveDate, OverOT, OTSched, RecipOpt, JobCraft)
     				(select PRCo, Craft, @desttemplate, OverEffectDate, 
     				EffectiveDate, OverOT, OTSched, RecipOpt, JobCraft
     				from dbo.PRCT with (nolock) 
     				where PRCo = @prco and Template = @sourcetemplate and Craft = @sourcecraft)
     	
     			if @@error = 1
     			begin 
     				select @msg = 'Error copying Craft Template', @rcode = 1
     				rollback transaction
     				goto bspexit
     			end
     	
     			if @notesyn = 'Y'
     			begin
     				update d
     				set d.Notes = s.Notes
     				from dbo.PRCT d with (nolock) join dbo.PRCT s with (nolock) on 
     				d.PRCo = s.PRCo and d.Craft = s.Craft
     				where d.PRCo = @prco and d.Template = @desttemplate and s.Template = @sourcetemplate and
     				s.Craft = @sourcecraft
     	
     				if @@error = 1
     				begin 
     					select @msg = 'Error copying Craft Template Notes', @rcode = 1
     					rollback transaction
     					goto bspexit
     				end
     			end
     		end
     	
     		--Craft Info - Grids. 
     		if @addonearnyn = 'Y'
     		begin
     			insert dbo.PRTI (PRCo, Craft, Template, EDLType, EDLCode, Factor,
     				OldRate, NewRate, UniqueAttchID)
     			(select s.PRCo, s.Craft, @desttemplate, s.EDLType, s.EDLCode, s.Factor, 
     			s.OldRate, s.NewRate, s.UniqueAttchID 
     			from dbo.PRTI s with (nolock) join dbo.PREC e with (nolock) on 
     			s.PRCo = e.PRCo and s.EDLCode = e.EarnCode
     			where s.PRCo = @prco and s.Craft = @sourcecraft and
     			s.Template = @sourcetemplate and s.EDLType = 'E'
     			and not exists (select 1 from dbo.PRTI d with (nolock) where s.PRCo = d.PRCo and 
     			s.Craft = d.Craft and s.EDLType = d.EDLType and s.EDLCode = d.EDLCode 
     			and d.PRCo = @prco and d.Craft = @sourcecraft and d.EDLType = 'E' and 
     			d.Template = @desttemplate))
     	
     			if @@error = 1
     			begin 
     				select @msg = 'Error copying Craft Template Add-on Earnings', @rcode = 1
     				rollback transaction
     				goto bspexit
     			end
     		end
     	
     		if @dedliabyn = 'Y'
     		begin
     			insert dbo.PRTI (PRCo, Craft, Template, EDLType, EDLCode, Factor,
     				OldRate, NewRate, UniqueAttchID)
     			(select s.PRCo, s.Craft, @desttemplate, s.EDLType, s.EDLCode, s.Factor, 
     			s.OldRate, s.NewRate, s.UniqueAttchID 
     			from dbo.PRTI s with (nolock) join dbo.PRDL l with (nolock) on 
     			s.PRCo = l.PRCo and s.EDLCode = l.DLCode and s.EDLType = l.DLType 
     			where s.PRCo = @prco and s.Craft = @sourcecraft and
     			s.Template = @sourcetemplate and s.EDLType in ('D', 'L')
     			and not exists (select 1 from dbo.PRTI d with (nolock) where s.PRCo = d.PRCo and 
     			s.Craft = d.Craft and s.EDLType = d.EDLType and s.EDLCode = d.EDLCode 
     			and d.PRCo = @prco and d.Craft = @sourcecraft and (d.EDLType = 'D' or EDLType = 'L') and 
     			d.Template = @desttemplate))
     	
     			if @@error = 1
     			begin 
     				select @msg = 'Error copying Craft Template Deduction/Liability codes', @rcode = 1
     				rollback transaction
     				goto bspexit
     			end
     		end
     	
     		if @jcitemsyn = 'Y'
     		begin
     			insert dbo.PRTR (PRCo, Craft, Template, DLCode, UniqueAttchID)
     			(select s.PRCo, s.Craft, @desttemplate, s.DLCode, s.UniqueAttchID 
     			from dbo.PRTR s with (nolock) join dbo.PRDL l with (nolock) on 
     			s.PRCo = l.PRCo and s.DLCode = l.DLCode
     			where s.PRCo = @prco and s.Craft = @sourcecraft and
     			s.Template = @sourcetemplate 
     			and not exists (select 1 from dbo.PRTR d with (nolock) where s.PRCo = d.PRCo and 
     			s.Craft = d.Craft and s.DLCode = d.DLCode 
     			and d.PRCo = @prco and d.Craft = @sourcecraft and d.Template = @desttemplate))
     	
     			if @@error = 1
     			begin 
     				select @msg = 'Error copying Craft Template Job Craft Item codes', @rcode = 1
     				rollback transaction
     				goto bspexit
     			end
     		end
     
     
     		--Now copy the Craft/Class Template info for this Craft.  Only copying over those entries
     		--that do not currently exist in the destination template.
     		--Craft Header
     		insert dbo.PRTC (PRCo, Craft, Class, Template, OverCapLimit, OldCapLimit, NewCapLimit)
     		(select s.PRCo, s.Craft, s.Class, @desttemplate, s.OverCapLimit, s.OldCapLimit, s.NewCapLimit
     		from dbo.PRTC s 
     		where s.PRCo = @prco and s.Craft = @sourcecraft and Template = @sourcetemplate 
     		and not exists (select 1 from dbo.PRTC d with (nolock) where s.PRCo = d.PRCo and s.Craft = d.Craft 
     		and s.Class = d.Class and d.PRCo = @prco and d.Craft = @sourcecraft and d.Template = @desttemplate))
     	
     		if @@error = 1
     		begin 
     			select @msg = 'Error copying Craft Class Template', @rcode = 1
     			rollback transaction
     			goto bspexit
     		end
     	
 
     		if @notesyn = 'Y'  --need to test this
     		begin
     			update d
     			set d.Notes = s.Notes
     			from dbo.PRTC d with (nolock) join dbo.PRTC s with (nolock) on 
     			d.PRCo = s.PRCo and d.Craft = s.Craft and d.Class = s.Class
     			where d.PRCo = @prco and d.Template = @desttemplate and s.Template = @sourcetemplate and
     			s.Craft = @sourcecraft
     	
     			if @@error = 1
     			begin 
     				select @msg = 'Error copying Craft Template Notes', @rcode = 1
     				rollback transaction
     				goto bspexit
     			end
     		end
     	
     		--Copy Pay Rates
     		if @payrateyn = 'Y'
     		begin
     			insert dbo.PRTP (PRCo, Craft, Class, Template, Shift, OldRate, NewRate, UniqueAttchID)
     			(select p.PRCo, p.Craft, p.Class, @desttemplate, p.Shift, p.OldRate, p.NewRate, p.UniqueAttchID
     			from dbo.PRTP p with (nolock)
     			where p.PRCo = @prco and p.Craft = @sourcecraft and Template = @sourcetemplate
     			and not exists (select 1 from dbo.PRTP d with (nolock) where p.PRCo = d.PRCo and p.Craft = d.Craft and 
     			p.Class = d.Class and p.Shift = d.Shift and  d.PRCo = @prco and d.Craft = @sourcecraft and d.Template = @desttemplate))
     	
     			if @@error = 1
     			begin 
     				select @msg = 'Error copying Craft Class Template Pay Rate codes', @rcode = 1
     				rollback transaction
     				goto bspexit
     			end
     		end
     
     		if @variableearnyn = 'Y'
     		begin
     			insert dbo.PRTE (PRCo, Craft, Class, Template, Shift, EarnCode, OldRate, NewRate, UniqueAttchID)
     			(select p.PRCo, p.Craft, p.Class, @desttemplate, p.Shift, p.EarnCode, p.OldRate, p.NewRate, p.UniqueAttchID
     			from dbo.PRTE p with (nolock) join dbo.PREC e with (nolock) on
     			p.PRCo = e.PRCo and p.EarnCode = e.EarnCode
     			where p.PRCo = @prco and p.Craft = @sourcecraft and Template = @sourcetemplate
     			and not exists (select 1 from dbo.PRTE d with (nolock) where p.PRCo = d.PRCo and p.Craft = d.Craft and 
     			p.Class = d.Class and p.Shift = d.Shift and p.EarnCode = d.EarnCode and d.PRCo = @prco and d.Craft = @sourcecraft and d.Template = @desttemplate))
     	
     			if @@error = 1
     			begin 
     				select @msg = 'Error copying Craft Class Template Variable Earnings codes', @rcode = 1
     				rollback transaction
     				goto bspexit
     			end
     		end
     
     		if @addonearnyn = 'Y'
     		begin
     			insert dbo.PRTF (PRCo, Craft, Class, Template, EarnCode, Factor, OldRate, NewRate, UniqueAttchID)
     			(select p.PRCo, p.Craft, p.Class, @desttemplate, p.EarnCode, p.Factor, p.OldRate, p.NewRate, p.UniqueAttchID
     			from dbo.PRTF p with (nolock) join dbo.PREC e with (nolock) on
     			p.PRCo = e.PRCo and p.EarnCode = e.EarnCode
     			where p.PRCo = @prco and p.Craft = @sourcecraft and Template = @sourcetemplate
     			and not exists (select 1 from dbo.PRTF d with (nolock) where p.PRCo = d.PRCo and p.Craft = d.Craft and 
     			p.Class = d.Class and p.EarnCode = d.EarnCode and p.Factor = d.Factor and d.PRCo = @prco and d.Craft = @sourcecraft and d.Template = @desttemplate))
     
     			if @@error = 1
     			begin 
     				select @msg = 'Error copying Craft Class Template Add-on Earnings codes', @rcode = 1
     				rollback transaction
     				goto bspexit
     			end
     	
     		end
     	
     		if @dedliabyn = 'Y'
     		begin
     			insert dbo.PRTD (PRCo, Craft, Class, Template, DLCode, Factor, OldRate, NewRate, UniqueAttchID)
     			(select p.PRCo, p.Craft, p.Class, @desttemplate, p.DLCode, p.Factor, p.OldRate, p.NewRate, p.UniqueAttchID
     			from dbo.PRTD p with (nolock) join dbo.PRDL l with (nolock) on 
     			p.PRCo = l.PRCo and p.DLCode = l.DLCode 
     			where p.PRCo = @prco and p.Craft = @sourcecraft and Template = @sourcetemplate
     			and not exists (select 1 from dbo.PRTD d with (nolock) where p.PRCo = d.PRCo and p.Craft = d.Craft and 
     			p.Class = d.Class and p.DLCode = d.DLCode and p.Factor = d.Factor and d.PRCo = @prco and d.Craft = @sourcecraft and d.Template = @desttemplate))
     	
     			if @@error = 1
     			begin 
     				select @msg = 'Error copying Craft Class Template Pay Rate codes', @rcode = 1
     				rollback transaction
     				goto bspexit
     			end
     		end
     
     	commit transaction
     
     
     	end
     
     bspexit:
     
          return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRTemplateCraftClassCopy] TO [public]
GO
