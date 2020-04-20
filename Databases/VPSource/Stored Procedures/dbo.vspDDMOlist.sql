SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspDDMOlist    Script Date: 8/28/99 9:35:50 AM ******/
   CREATE proc [dbo].[vspDDMOlist] as
   /** This Procedure displays modules and titles set up in vDDMO **/
   set nocount on 
   begin
     select * from vDDMO order by Mod asc
   end

GO
GRANT EXECUTE ON  [dbo].[vspDDMOlist] TO [public]
GO
