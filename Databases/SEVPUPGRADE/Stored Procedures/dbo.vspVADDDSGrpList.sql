SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[vspVADDDSGrpList]
   /************************************************************************
   * Object:  Stored Procedure dbo.bspVADDDSGrpList 
   *
   * Created: ???
   * Modified: RBT 07/24/03 - Issue #17312, sort by SecurityGroup
   *		   AL  04/10/07 - 6x Recode added a check to ensure the group is 
   *		                  of Group Type 0-Data
   *		TJL 03/24/09 - Issue #132867 - ANSI Null evaluating FALSE instead of TRUE
   *
   *************************************************************************  
   * displays security set up in bDDDS for a given Datatype, Qualifier & Instance
   * ordered by Security Group
   * input:  datatype, qualifier, instance, msg
   * output: securitygrp, Description, SecGrant(None,Full)
   * 10/16/96 LM 
   **************************************************************************/
   	(@datatype varchar(30)=null, @qualifier tinyint=0, @instance char(30)=null,   
   	@msg varchar(60) output) as
set nocount on 
   declare @rcode integer
   select @rcode = 0
   
   begin
   
   if (select count(*) from bDDDT where  Datatype = @datatype)<>1
   	begin
   	select @msg = 'Datatype not in DDDT!', @rcode = 1
   	goto bspexit
   	end
   
   select g.SecurityGroup, g.Description, SecGrant=
     case (case isnull(count(d.SecurityGroup), -2) when -2 then -1 when 0 then -1
   		else 0
    	end)
        when -1 then 'True'
        when  0 then 'False'
     end 
   from vDDSG g LEFT OUTER JOIN vDDDS d on g.SecurityGroup = d.SecurityGroup
   and d.Datatype=@datatype
       and d.Qualifier =@qualifier
       and d.Instance  =@instance
		where g.GroupType = 0
       group by g.SecurityGroup, g.Description
   	order by g.SecurityGroup
   
   
   bspexit:
   	return @rcode    
   end

GO
GRANT EXECUTE ON  [dbo].[vspVADDDSGrpList] TO [public]
GO
