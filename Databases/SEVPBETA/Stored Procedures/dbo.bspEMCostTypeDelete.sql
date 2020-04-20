SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   proc [dbo].[bspEMCostTypeDelete]
    /****************************************************
    *
    *    Created by: TV 07/01/03
    *				TV 02/11/04 - 23061 added isnulls	
    *    Purpose in life: A trickle down clean up of EMCD, EMMC, and EMCH
    *                     when thes Cost Type is removed from the Cost Code
    *    inputs:
    *           @EMCo
    *           @EMGroup
    *           @CostCode
    *           @CostType
    *           @errmsg
    *
    *    Outputs:
    *           @errmsg
    *
    ****************************************************/
    (@EMCo bCompany, @EMGroup bGroup, @CostCode bCostCode, @CostType bEMCType, @errmsg varchar(255)output)
    
    as 
    set nocount on
    
    declare @rcode int
    select @rcode = 0
    --validate the passed in params. 'can't do nuthin without em'
    if isnull(@EMCo, '') = ''
        begin 
        select @errmsg = 'EMCo cannot be null', @rcode = 1  
        goto bspexit
        end
    if isnull(@EMGroup, '') = ''
        begin 
        select @errmsg = 'EMGroup cannot be null', @rcode = 1  
        goto bspexit
        end
    if isnull(@CostCode, '') = ''
        begin 
        select @errmsg = 'CostCode cannot be null', @rcode = 1  
        goto bspexit
        end
    if isnull(@CostType, '') = ''
        begin 
        select @errmsg = 'CostType cannot be null', @rcode = 1  
        goto bspexit
        end
    
    --need to clean up EMCD
    /*delete EMCD 
    where EMCo = @EMCo and EMGroup = @EMGroup and CostCode = @CostCode and EMCostType = @CostType
    If @@Error <> 0
        begin
        select @errmsg = 'EMCD records still exists.', @rcode = 1
        goto bspexit
        end*/
    
    --need to clean up EMMC
    delete EMMC 
    where EMCo = @EMCo and EMGroup = @EMGroup and CostCode = @CostCode and CostType = @CostType
    If @@Error <> 0
        begin
        select @errmsg = 'EMMC records still exists.', @rcode = 1
        goto bspexit
        end
    
    --need to clean up EMCH
    delete EMCH
    where EMCo = @EMCo and EMGroup = @EMGroup and CostCode = @CostCode and CostType = @CostType
    If @@Error <> 0
        begin
        select @errmsg = 'EMCH records still exists.', @rcode = 1
        goto bspexit
        end
    
    
    bspexit:
    
    if @rcode <> 0
        begin
        select @errmsg = isnull(@errmsg,'')		--+ ' bspEMCostTypeDelete'
        end
    
    Return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspEMCostTypeDelete] TO [public]
GO
