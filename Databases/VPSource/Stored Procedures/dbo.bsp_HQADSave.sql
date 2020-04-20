SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[bsp_HQADSave] as 
   /******************************************
   	Created: RM 09/16/02
   
   	Saves HQAD records during build process to be restored later.
   ******************************************/
   
   if exists(select * from sysobjects where name='bHQADSave' and type='U')
   	drop table bHQADSave
   
   	select * into bHQADSave from bHQAD where Custom='Y'

GO
GRANT EXECUTE ON  [dbo].[bsp_HQADSave] TO [public]
GO
