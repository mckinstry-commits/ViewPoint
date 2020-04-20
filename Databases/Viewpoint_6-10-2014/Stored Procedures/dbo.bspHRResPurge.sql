SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspHRResPurge    Script Date: 8/28/99 9:34:57 AM ******/
      CREATE   procedure [dbo].[bspHRResPurge]
      /*************************************
      * CREATED BY:  ae 5/15/1999
      *  Mod JRE 6/28/01  fixed Involved in an accident and cannot be removed. by adding @rcode=1
      *  Mod JRE 6/28/01  change ' to '
      *
      *    Issue 13872 - per Carol and Kate, if the Resource is in bHRAI, delete everything
      *                except the bHRRM and bHRAI records. mh 7/11/01
	  *
	  *		Issue 28020 - Reviewed sp.  Made sure the child records are deleted before parent records.
      *
      * Deletes All records for a given resource
      *
      * Pass:
      *   HRCo - Human Resources Company
      *   HRRef - Resource ID to be Purged
      *
      * Error returns:
      *	1 and error message
      **************************************/
      	(@HRCo bCompany = null, @HRRef bHRRef, @msg varchar(75) output)
      as
      	set nocount on
      	declare @rcode int
         	select @rcode = 0
   
      if @HRCo is null
      	begin
      	select @msg = 'Missing HR Company', @rcode = 1
      	goto bspexit
      	end
   
      if @HRRef is null
      	begin
      	select @msg = 'Missing HR Resource Number', @rcode = 1
      	goto bspexit
      	end
   
      /* Check bHRAI for detail */
   /*
      if exists(select * from bHRAI where bHRAI.HRCo = @HRCo and bHRAI.HRRef = @HRRef)
           begin
            select @msg = 'Involved in an accident and cannot be removed.  Entries exist in bHRAI', @rcode = 1
            goto bspexit
           end
   */
   
      delete from HRWI
         where HRCo = @HRCo and HRRef = @HRRef
      delete from HREC
         where HRCo = @HRCo and HRRef = @HRRef
      delete from HRDP
         where HRCo = @HRCo and HRRef = @HRRef
--Issue 120395 and 28020
	  delete from HRBL 
		 where HRCo = @HRCo and HRRef = @HRRef
	  delete from HRBE 
		 where HRCo = @HRCo and HRRef = @HRRef
--End Issue 120395
      delete from HREB
         where HRCo = @HRCo and HRRef = @HRRef
      delete from HRSP
         where HRCo = @HRCo and HRRef = @HRRef
      delete from HRSH
         where HRCo = @HRCo and HRRef = @HRRef
      delete from HRRP
         where HRCo = @HRCo and HRRef = @HRRef
      delete from HRER
         where HRCo = @HRCo and HRRef = @HRRef
      delete from HRES
         where HRCo = @HRCo and HRRef = @HRRef
      delete from HRET
         where HRCo = @HRCo and HRRef = @HRRef
      delete from HRRS
         where HRCo = @HRCo and HRRef = @HRRef
      delete from HRRD
         where HRCo = @HRCo and HRRef = @HRRef
      delete from HRED
         where HRCo = @HRCo and HRRef = @HRRef
      delete from HREG
         where HRCo = @HRCo and HRRef = @HRRef
      delete from HRRC
         where HRCo = @HRCo and HRRef = @HRRef
      delete from HRAR
         where HRCo = @HRCo and HRRef = @HRRef
      delete from HRAP
         where HRCo = @HRCo and HRRef = @HRRef
      delete from HREI
         where HRCo = @HRCo and HRRef = @HRRef
      delete from HRDT
         where HRCo = @HRCo and HRRef = @HRRef
   /*
      delete from HRRM
         where HRCo = @HRCo and HRRef = @HRRef
   */

      delete from HREH
         where HRCo = @HRCo and HRRef = @HRRef

      if not exists(select * from bHRAI where bHRAI.HRCo = @HRCo and bHRAI.HRRef = @HRRef)
           begin
   			delete from HRRM
   		    where HRCo = @HRCo and HRRef = @HRRef
           end
   
   
   
      bspexit:
      	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHRResPurge] TO [public]
GO
