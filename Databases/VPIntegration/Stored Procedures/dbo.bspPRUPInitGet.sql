SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRUPInitGet    Script Date: 8/28/99 9:35:39 AM ******/
    
    CREATE       procedure [dbo].[bspPRUPInitGet]
    /***********************************************************
     * CREATED BY: EN 12/29/00
     * MODIFIED BY:	EN 12/14/01 - issue 13557
     *				EN 3/5/02 - issues 14180/14181/14735 return values craft1, equipphase1, costtype1, and craft2
     *				EN 9/4/02 - issue 18448 values craft1, equipphase1, costtype1, and craft2 not being init. for new users
     *				EN 10/9/02 - issue 18877 change double quotes to single
     *
     * USAGE:
     * Depending on @init flag, either initializes a PRUP entry or gets the values of an existing
     * entry.  In either cases, returns the values which were initialized/read.
     *
     *  INPUT PARAMETERS
     *   @prco - company
     *   @init - 'Y' to initialize PRUP entry, else 'N' to just get values
     *
     * OUTPUT PARAMETERS
     *   @msg      error message if error occurs
     *
     * RETURN VALUE
     *   0         success
     *   1         Failure
     *****************************************************/
    	(@prco bCompany = null, @init char(1) = 'N', @user bVPUserName, @jcco1 tinyint output, @glco tinyint output,
        @inscode1 tinyint output, @emco1 tinyint output, @equip tinyint output, @class1 tinyint output,
        @shift1 tinyint output, @rate1 tinyint output, @amt1 tinyint output, @emco2 tinyint output,
        @emco3 tinyint output, @wo tinyint output, @woitem tinyint output, @comptype tinyint output,
        @comp tinyint output, @inscode2 tinyint output, @class2 tinyint output, @shift2 tinyint output,
        @rate2 tinyint output, @amt2 tinyint output, @jcco2 tinyint output, @job tinyint output,
        @prdept1 tinyint output, @prdept2 tinyint output, @memo1 tinyint output, @memo2 tinyint output,
        @craft1 tinyint output, @equipphase1 tinyint output, @costtype1 tinyint output,
    	@craft2 tinyint output, @msg varchar(60) output)
    as
    set nocount on
    
    declare @rcode int
    
    select @rcode = 0
    
    select @jcco1=JCCo1, @glco=GLCo, @inscode1=InsCode1, @emco1=EMCo1, @equip=Equip, @class1=Class1,
        @shift1=Shift1, @rate1=Rate1, @amt1=Amt1, @emco2=EMCo2, @emco3=EMCo3, @wo=WO, @woitem=WOItem,
        @comptype=CompType, @comp=Comp, @inscode2=InsCode2, @class2=Class2, @shift2=Shift2, @rate2=Rate2,
        @amt2=Amt2, @jcco2=JCCo2, @job=Job, @prdept1=PRDept1, @prdept2=PRDept2, @memo1=Memo1, @memo2=Memo2,
    	@craft1=Craft1, @equipphase1=EquipPhase1, @costtype1=CostType1, @craft2=Craft2 --issues 14180/14181/14735
    from PRUP where PRCo = @prco and UserName = @user
    
    if @@rowcount = 0
        begin
        if @init = 'Y'
            begin
            select @jcco1=2, @glco=2, @inscode1=2,
                @emco1=0, --issue 13557 - was: @emco1=Case when EMCo is not null and EMUsage='N' then 0 else 2 end,
                @equip=0, --issue 13557 - was: @equip=Case when EMCo is not null and EMUsage='N' then 0 else 2 end,
                @class1=2, @shift1=2, @rate1=2, @amt1=2, 
    			@emco2=Case when EMCo is not null and EMUsage='N' then 0 else 2 end, --issue 13557 - was: @emco2=0,
    			@emco3=2, @wo=2, @woitem=2, @comptype=2,
                @comp=2, @inscode2=2, @class2=2, @shift2=2, @rate2=2, @amt2=2, @jcco2=2, @job=2, @prdept1=2,
                @prdept2=2, @memo1=2, @memo2=2, @craft1=2, @equipphase1=2, @costtype1=2, @craft2=2 --issue 18448
            from PRCO where PRCo = @prco
            insert PRUP (PRCo, UserName, JCCo1, GLCo, InsCode1, EMCo1, Equip, EMCo2, Class1, Shift1, Rate1,
                    Amt1, EMCo3, WO, WOItem, CompType, Comp, InsCode2, Class2, Shift2, Rate2, Amt2, JCCo2,
                    Job, PRDept1, PRDept2, Memo1, Memo2)
            values (@prco, @user, @jcco1, @glco, @inscode1, @emco1, @equip, @emco2, @class1, @shift1,
                    @rate1, @amt1, @emco3, @wo, @woitem, @comptype, @comp, @inscode2, @class2, @shift2,
                    @rate2, @amt2, @jcco2, @job, @prdept1, @prdept2, @memo1, @memo2)
            if @@rowcount = 0
                begin
                select @msg = 'Initialization failed!', @rcode = 1
                goto bspexit
                end
            end
        if @init <> 'Y'
            begin
            select @msg = 'User Options not found!', @rcode = 1
            goto bspexit
            end
        end
    
    
    bspexit:
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRUPInitGet] TO [public]
GO
