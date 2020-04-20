SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE         procedure [dbo].[bspPRTemplateStdCraftClassCopy]
   /************************************************************************
   * CREATED:  mh 8/6/2004    
   * MODIFIED:    
   *
   * Purpose of Stored Procedure
   *
   *	Copies Standard Crafts and Craft/Classes to a specified Template.  
   *	Either all Crafts and Crafts Classes will be copied or a specified
   *	Craft and it's Craft/Classes depending on @whatcrafts flag.  Will not 
   *	overwrite any existing Template Craft and Craft/Class entries with the
   *	exception of Notes.
   *           
   * Notes about Stored Procedure
   *
   *	@prco - Payroll Company
   *	@whatcrafts - Flag to determine if "all" or a "single" craft is copied.
   *	@sourcecraft - Source Craft
   *	@payrateyn - Include Pay Rates
   *	@addonearnyn - Include Add On Earnings
   *	@variableearnyn - Include Variable Earnings
   *	@dedliabyn - Include Deduction/Liabilities
   *	@notesyn - Include Notes
   *	@desttemplate - Destination Template    
   *    
   * 
   *
   * returns 0 if successfull 
   * returns 1 and error msg if failed
   *
   *************************************************************************/
   
   	(@prco bCompany, @whatcrafts char(1) = 'N', @sourcecraft bCraft, @payrateyn bYN = 'N', 
   	@addonearnyn bYN = 'N', @variableearnyn bYN = 'N', @dedliabyn bYN = 'N', @notesyn bYN = 'N', 
   	@desttemplate smallint, @msg varchar(100) = '' output)
   
   as
   set nocount on
   
       declare @rcode int
   
       select @rcode = 0
   
   	if @whatcrafts = 'A'
   	begin
   
   		Begin Transaction
   	
   		--Insert Craft Template
   		insert dbo.PRCT (PRCo, Craft, Template, OverEffectDate, OverOT, RecipOpt)
   		(select m.PRCo, m.Craft, @desttemplate, 'N', 'N', 'N' 
   		from dbo.PRCM m with (nolock) where m.PRCo = @prco and not exists
   		(select 1 from dbo.PRCT t with (nolock) where t.PRCo = m.PRCo and t.Craft = m.Craft and
   		t.PRCo = @prco and t.Template = @desttemplate))	
   
   		if @@error = 1
   		begin 
   			select @msg = 'Error copying Standard Craft to Craft Template', @rcode = 1
   			rollback transaction
   			goto bspexit
   		end
   
   		if @notesyn = 'Y'
   		begin
   			--copy notes
   			update d
   			set d.Notes = s.Notes
   			from dbo.PRCT d with (nolock) join dbo.PRCM s with (nolock) on
   			s.PRCo = d.PRCo and s.Craft = d.Craft 
   			where s.PRCo = @prco and d.Template = @desttemplate and s.Notes is not null
   
   			if @@error = 1
   			begin 
   				select @msg = 'Error copying Standard Craft Notes to Craft Template Notes', @rcode = 1
   				rollback transaction
   				goto bspexit
   			end
   		end
   
   		--Insert Add On Earn Template Items
   
   		if @addonearnyn = 'Y'
   		begin	
   			insert dbo.PRTI (PRCo, Craft, Template, EDLType, EDLCode, Factor, OldRate, NewRate) 
   			(select i.PRCo, i.Craft, @desttemplate, i.EDLType, i.EDLCode, i.Factor, i.OldRate, i.NewRate 
   			from dbo.PRCI i with (nolock) join dbo.PREC e with (nolock) on 
   			i.PRCo = e.PRCo and i.EDLCode = e.EarnCode
   			where i.PRCo = @prco and i.EDLType = 'E' and not exists
   			(select 1 from dbo.PRTI t with (nolock) where t.PRCo = i.PRCo and t.Craft = i.Craft and t.PRCo = @prco and
   			t.EDLType = 'E' and t.Template = @desttemplate))
   
   			if @@error = 1
   			begin 
   				select @msg = 'Error copying Standard Craft Add-on Earnings to Craft Template Add-on Earnings', @rcode = 1
   				rollback transaction
   				goto bspexit
   			end
   		end
   
   		--Insert Deductons and Liablities
   
   		if @dedliabyn = 'Y'
   		begin	
   			insert dbo.PRTI (PRCo, Craft, Template, EDLType, EDLCode, Factor, OldRate, NewRate)
   			(select i.PRCo, i.Craft, @desttemplate, i.EDLType, i.EDLCode, i.Factor, i.OldRate, i.NewRate 
   			from dbo.PRCI i with (nolock) join dbo.PRDL l with (nolock) on 
   			i.PRCo = l.PRCo and i.EDLCode = l.DLCode and i.EDLType = l.DLType 
   			where i.PRCo = @prco and i.EDLType in ('D', 'L') 
   			and not exists
   			(select 1 from dbo.PRTI t with (nolock) where t.PRCo = i.PRCo and t.Craft = i.Craft and 
   			t.PRCo = @prco and t.EDLType in ('D', 'L') and t.Template = @desttemplate))
   
   			if @@error = 1
   			begin 
   				select @msg = 'Error copying Standard Craft Deduction/Liability codes to Craft Template Deduction/Liability codes', @rcode = 1
   				rollback transaction
   				goto bspexit
   			end
   		end
   
   		--Insert Craft/Classes Template Header
   		insert dbo.PRTC (PRCo, Craft, Class, Template, OverCapLimit)
   		(select c.PRCo, c.Craft, c.Class, @desttemplate, 'N' from dbo.PRCC c with (nolock) where c.PRCo = @prco and not exists
   		(select 1 from dbo.PRTC t with (nolock) where t.PRCo = c.PRCo and t.Craft = c.Craft and c.Class = t.Class
   		and t.Template = @desttemplate))
   
   		if @@error = 1
   		begin 
   			select @msg = 'Error copying Standard Craft to Craft Class Template', @rcode = 1
   			rollback transaction
   			goto bspexit
   		end
   
   		--Update Craft/Class Notes
   
   		if @notesyn = 'Y'
   		begin
   			update d
   			set d.Notes = s.Notes 
   			from dbo.PRCC s with (nolock) join dbo.PRTC d with (nolock) on 
   			s.PRCo = d.PRCo and s.Craft = d.Craft and s.Class = d.Class
   			where s.PRCo = @prco and d.Template = @desttemplate and s.Notes is not null
   
   			if @@error = 1
   			begin 
   				select @msg = 'Error copying Standard Craft Notes to Craft Template Notes', @rcode = 1
   				rollback transaction
   				goto bspexit
   			end
   		end
   
   		--Insert Craft/Class Template PayRates
   
   		if @payrateyn = 'Y'
   		begin	
   			insert dbo.PRTP (PRCo, Craft, Class, Template, Shift, OldRate, NewRate)
   			(select p.PRCo, p.Craft, p.Class, @desttemplate, p.Shift, p.OldRate, p.NewRate 
   			from dbo.PRCP p with (nolock) where p.PRCo = @prco and not exists
   			(select 1 from dbo.PRTP t with (nolock) where t.PRCo = p.PRCo and t.Craft = p.Craft and t.Class = p.Class
   			and t.Shift = p.Shift and t.Template = @desttemplate))
   
   			if @@error = 1
   			begin 
   				select @msg = 'Error copying Standard Craft Pay Rate codes to Craft Class Template Pay Rate codes', @rcode = 1
   				rollback transaction
   				goto bspexit
   			end
   		end
   	
   		--Insert Craft/Class Template Variable Earnings
   
   		if @variableearnyn = 'Y'
   		begin
   			insert dbo.PRTE (PRCo, Craft, Class, Template, Shift, EarnCode, OldRate, NewRate)
   			(select c.PRCo, c.Craft, c.Class, @desttemplate, c.Shift, c.EarnCode, c.OldRate, c.NewRate 
   			from dbo.PRCE c with (nolock) join dbo.PREC e with (nolock) on
   			c.PRCo = e.PRCo and c.EarnCode = e.EarnCode 
   			where c.PRCo = @prco and not exists
   			(select 1 from dbo.PRTE t with (nolock) where t.PRCo = c.PRCo and t.Craft = c.Craft and t.Class = c.Class
   			and t.Shift = c.Shift and t.EarnCode = c.EarnCode and t.Template = @desttemplate))
   
   			if @@error = 1
   			begin 
   				select @msg = 'Error copying Standard Craft Variable Earnings codes to Craft Class Template Variable Earnings codes', @rcode = 1
   				rollback transaction
   				goto bspexit
   			end
   		end
   
   		--Insert Craft/Class Template Add on Earnings
   
   		if @addonearnyn = 'Y'
   		begin	
   			insert dbo.PRTF (PRCo, Craft, Class, Template, EarnCode, Factor, OldRate, NewRate)
   			(select f.PRCo, f.Craft, f.Class, @desttemplate, f.EarnCode, f.Factor, 
   			f.OldRate, f.NewRate
   			from dbo.PRCF f with (nolock) join dbo.PREC e with (nolock) on
   			f.PRCo = e.PRCo and f.EarnCode = e.EarnCode
   			where f.PRCo = @prco and not exists
   			(select 1 from dbo.PRTF t with (nolock) where t.PRCo = f.PRCo and t.Craft = f.Craft and 
   			t.Class = f.Class and t.EarnCode = f.EarnCode and t.Factor = f.Factor and 
   			t.Template = @desttemplate))
   
   			if @@error = 1
   			begin 
   				select @msg = 'Error copying Standard Craft Add-on Earnings codes to Craft Class Template Add-on Earnings codes', @rcode = 1
   				rollback transaction
   				goto bspexit
   			end
   		end
   
   		--Insert Craft/Class Template Dedn/Liab Earnings
   
   		if @dedliabyn = 'Y'
   		begin	
   			insert dbo.PRTD (PRCo, Craft, Class, Template, DLCode, Factor, OldRate, NewRate)
   			(select c.PRCo, c.Craft, c.Class, @desttemplate, c.DLCode, c.Factor, c.OldRate,
   			c.NewRate from dbo.PRCD c with (nolock) join dbo.PRDL l with (nolock) on 
   			c.PRCo = l.PRCo and c.DLCode = l.DLCode 
   			where c.PRCo = @prco and not exists
   			(select 1 from dbo.PRTD d with (nolock) where d.PRCo = c.PRCo and d.Craft = c.Craft and d.Class = c.Class and
   			d.DLCode = c.DLCode and d.Factor = c.Factor and d.Template = @desttemplate))
   
   			if @@error = 1
   			begin 
   				select @msg = 'Error copying Standard Craft Pay Rate codes to Craft Class Template Pay Rate codes', @rcode = 1
   				rollback transaction
   				goto bspexit
   			end
   		end
   
   		commit transaction
   	end
   
   	if @whatcrafts = 'S'
   	begin
   
   		begin transaction
   
   		--Insert Craft Template
   		insert dbo.PRCT (PRCo, Craft, Template, OverEffectDate, OverOT, RecipOpt)
   		(select m.PRCo, m.Craft, @desttemplate, 'N', 'N', 'N' 
   		from dbo.PRCM m with (nolock) where m.PRCo = @prco and m.Craft = @sourcecraft and not exists
   		(select 1 from dbo.PRCT t with (nolock) where t.PRCo = m.PRCo and t.Craft = m.Craft and
   		t.PRCo = @prco and t.Template = @desttemplate))	
   
   		if @@error = 1
   		begin 
   			select @msg = 'Error copying Standard Craft to Craft Template', @rcode = 1
   			rollback transaction
   			goto bspexit
   		end
   		--copy notes
   
   		if @notesyn = 'Y'
   		begin
   			update d
   			set d.Notes = s.Notes
   			from dbo.PRCT d with (nolock) join dbo.PRCM s with (nolock) on
   			s.PRCo = d.PRCo and s.Craft = d.Craft 
   			where s.PRCo = @prco and d.Template = @desttemplate and d.Craft = @sourcecraft and 
   			s.Notes is not null
   
   			if @@error = 1
   			begin 
   				select @msg = 'Error copying Standard Craft Template Notes to Craft Template Notes', @rcode = 1
   				rollback transaction
   				goto bspexit
   			end
   
   		end
   		
   		--Insert Add-on Earn Template Items
   
   		if @addonearnyn = 'Y'
   		begin		
   			insert dbo.PRTI (PRCo, Craft, Template, EDLType, EDLCode, Factor, OldRate, NewRate) 
   			(select i.PRCo, i.Craft, @desttemplate, i.EDLType, i.EDLCode, i.Factor, i.OldRate, i.NewRate 
   			from dbo.PRCI i with (nolock) join dbo.PREC e with (nolock) on 
   			i.PRCo = e.PRCo and i.EDLCode = e.EarnCode 
   			where i.PRCo = @prco and i.EDLType = 'E' and i.Craft = @sourcecraft and not exists
   			(select 1 from dbo.PRTI t with (nolock) where t.PRCo = i.PRCo and t.Craft = i.Craft and t.PRCo = @prco and
   			t.EDLType = 'E' and t.EDLCode = i.EDLCode and t.Template = @desttemplate))
   
   			if @@error = 1
   			begin 
   				select @msg = 'Error copying Standard Craft Add-on Earnings to Craft Template Add-on Earnings', @rcode = 1
   				rollback transaction
   				goto bspexit
   			end
   		end
   
   		--Insert Deductons and Liablities
   
   		if @dedliabyn = 'Y'
   		begin		
   			insert dbo.PRTI (PRCo, Craft, Template, EDLType, EDLCode, Factor, OldRate, NewRate)
   			(select i.PRCo, i.Craft, @desttemplate, i.EDLType, i.EDLCode, i.Factor, i.OldRate, i.NewRate 
   			from dbo.PRCI i with (nolock) join dbo.PRDL l with (nolock) on 
   			i.PRCo = l.PRCo and i.EDLCode = l.DLCode and i.EDLType = l.DLType 
   			where i.PRCo = @prco and i.EDLType in ('D','L') 
   			and i.Craft = @sourcecraft and not exists
   			(select 1 from dbo.PRTI t with (nolock) where t.PRCo = i.PRCo and t.Craft = i.Craft and 
   			t.PRCo = @prco and t.EDLType in ('D','L') and t.EDLCode = i.EDLCode and t.Template = @desttemplate))
   
   			if @@error = 1
   			begin 
   				select @msg = 'Error copying Standard Craft Deduction/Liability codes to Craft Template Deduction/Liability codes', @rcode = 1
   				rollback transaction
   				goto bspexit
   			end
   		end
   	
   		--Insert Craft/Classes Template Header
   		insert dbo.PRTC (PRCo, Craft, Class, Template, OverCapLimit)
   		(select c.PRCo, c.Craft, c.Class, @desttemplate, 'N' 
   		from dbo.PRCC c with (nolock) where c.PRCo = @prco and c.Craft = @sourcecraft and not exists
   		(select 1 from dbo.PRTC t with (nolock) where t.PRCo = c.PRCo and t.Craft = c.Craft and c.Class = t.Class
   		and t.Template = @desttemplate))
   
   		if @@error = 1
   		begin 
   			select @msg = 'Error copying Standard Craft to Craft/Class Template Header.', @rcode = 1
   			rollback transaction
   			goto bspexit
   		end
   
   		if @notesyn = 'Y'
   		begin
   			update d
   			set d.Notes = s.Notes 
   			from dbo.PRCC s with (nolock) join dbo.PRTC d with (nolock) on 
   			s.PRCo = d.PRCo and s.Craft = d.Craft and s.Class = d.Class
   			where s.PRCo = @prco and d.Template = @desttemplate and d.Craft = @sourcecraft and
   			s.Notes is not null
   
   			if @@error = 1
   			begin 
   				select @msg = 'Error copying Standard Craft Notes to Craft Template Notes', @rcode = 1
   				rollback transaction
   				goto bspexit
   			end
   		end
   	
   		--Insert Craft/Class Template PayRates 
   
   		if @payrateyn = 'Y'
   		begin		
   			insert dbo.PRTP (PRCo, Craft, Class, Template, Shift, OldRate, NewRate)
   			(select p.PRCo, p.Craft, p.Class, @desttemplate, p.Shift, p.OldRate, p.NewRate 
   			from dbo.PRCP p with (nolock) where p.PRCo = @prco and p.Craft = @sourcecraft and not exists
   			(select 1 from dbo.PRTP t with (nolock) where t.PRCo = p.PRCo and t.Craft = p.Craft and t.Class = p.Class
   			and t.Shift = p.Shift and t.Template = @desttemplate))
   
   			if @@error = 1
   			begin 
   				select @msg = 'Error copying Standard Craft Pay Rate codes to Craft Class Template Pay Rate codes', @rcode = 1
   				rollback transaction
   				goto bspexit
   			end
   		end
   
   		--Insert Craft/Class Template Variable Earnings
   
   		if @variableearnyn = 'Y'
   		begin
   			insert dbo.PRTE (PRCo, Craft, Class, Template, Shift, EarnCode, OldRate, NewRate)
   			(select c.PRCo, c.Craft, c.Class, @desttemplate, c.Shift, c.EarnCode, c.OldRate, c.NewRate 
   			from dbo.PRCE c with (nolock) join dbo.PREC e with (nolock) on
   			c.PRCo = e.PRCo and c.EarnCode = e.EarnCode
   			where c.PRCo = @prco and c.Craft = @sourcecraft and not exists
   			(select 1 from dbo.PRTE t with (nolock) where t.PRCo = c.PRCo and t.Craft = c.Craft and t.Class = c.Class
   			and t.Shift = c.Shift and t.EarnCode = c.EarnCode and t.Template = @desttemplate))
   
   			if @@error = 1
   			begin 
   				select @msg = 'Error copying Standard Craft Variable Earnings codes to Craft Class Template Variable Earnings codes', @rcode = 1
   				rollback transaction
   				goto bspexit
   			end
   		end
   
   		--Insert Craft/Class Template Add on Earnings
   
   		if @addonearnyn = 'Y'
   		begin		
   			insert dbo.PRTF (PRCo, Craft, Class, Template, EarnCode, Factor, OldRate, NewRate)
   			(select f.PRCo, f.Craft, f.Class, @desttemplate, f.EarnCode, f.Factor, f.OldRate, f.NewRate
   			from dbo.PRCF f with (nolock) join dbo.PREC e with (nolock) on
   			f.PRCo = e.PRCo and f.EarnCode = e.EarnCode
   			where f.PRCo = @prco and f.Craft = @sourcecraft and not exists
   			(select 1 from dbo.PRTF t with (nolock) where t.PRCo = f.PRCo and t.Craft = f.Craft and 
   			t.Class = f.Class and t.EarnCode = f.EarnCode and t.Factor = f.Factor and 
   			t.Template = @desttemplate))
   
   			if @@error = 1
   			begin 
   				select @msg = 'Error copying Standard Craft Add-on Earnings codes to Craft Class Template Add-on Earnings codes', @rcode = 1
   				rollback transaction
   				goto bspexit
   			end
   		end
   
   		--Insert Craft/Class Template Dedn/Liab Earnings
   
   		if @dedliabyn = 'Y'
   		begin		
   			insert dbo.PRTD (PRCo, Craft, Class, Template, DLCode, Factor, OldRate, NewRate)
   			(select c.PRCo, c.Craft, c.Class, @desttemplate, c.DLCode, c.Factor, c.OldRate, c.NewRate 
   			from dbo.PRCD c with (nolock) join dbo.PRDL l with (nolock) on 
   			c.PRCo = l.PRCo and c.DLCode = l.DLCode  
   			where c.PRCo = @prco and c.Craft = @sourcecraft and not exists
   			(select 1 from dbo.PRTD d with (nolock) where d.PRCo = c.PRCo and d.Craft = c.Craft and d.Class = c.Class and
   			d.DLCode = c.DLCode and d.Factor = c.Factor and d.Template = @desttemplate))
   
   			if @@error = 1
   			begin 
   				select @msg = 'Error copying Standard Craft Pay Rate codes to Craft Class Template Pay Rate codes', @rcode = 1
   				rollback transaction
   				goto bspexit
   			end
   		end
   
   		commit transaction
   	end
   
   bspexit:
   
        return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRTemplateStdCraftClassCopy] TO [public]
GO
