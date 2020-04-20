SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspTriggersConnected    Script Date: 8/28/99 9:33:43 AM ******/
   CREATE proc [dbo].[bspTriggersConnected] (@Module char(2)=null)
   /* displays whether triggers exists for each table in a Module */
   /* Input  @Module */
   /* Output  Table name, Insert trigger, update trigger, delete trigger */
   /* JRE 05/20/97 */
   as
   set nocount on
   begin
   select name, deltrig, instrig, updtrig from sysobjects
   where substring(name,2,2)= @Module and type='U'
   order by name
   /*and (deltrig<>0 or instrig<>0 or updtrig<>0)*/
   end

GO
GRANT EXECUTE ON  [dbo].[bspTriggersConnected] TO [public]
GO
