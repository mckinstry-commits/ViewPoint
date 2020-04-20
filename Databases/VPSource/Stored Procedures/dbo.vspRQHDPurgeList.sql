SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspRQHDPurgeList    Script Date: 02/28/06  ******/
   CREATE   proc [dbo].[vspRQHDPurgeList]
   /***********************************************************
    * CREATED BY	: DC 01/08/2009 #25782
    * MODIFIED BY	: 
    *
    * USAGE:
	* This routine is used to load listbox with RQ's where Status = 5 i.e completed and
	* RQ Header Date is <= Purge through Month
	*
    *
    * INPUT PARAMETERS
    *   POCo  		PO Company
	*	MthClose	Closed Month
    *
	*
    * RETURN VALUE
    *   0         success
    *   1         Failure
    *****************************************************/
       (@poco bCompany = 0, @mthcompleted bMonth, @purgedenied bYN)  
   as
   
   set nocount on
   
	If @purgedenied = 'Y' 
		BEGIN
		select l.RQID, ': ' + isnull(h.Description,'')
		from RQRH h
		join RQRL l on l.RQCo = h.RQCo and h.RQID = l.RQID
		where h.RQCo = @poco
			And h.RecDate <= @mthcompleted
			and l.RQID not in (select l1.RQID
					from RQRL l1
					Where l1.RQCo = @poco
					and l1.Status < 5)	
		group by l.RQID, h.Description
		END
	ELSE
		BEGIN
		select l.RQID, ': ' + isnull(h.Description,'')
		from RQRH h
		join RQRL l on l.RQCo = h.RQCo and h.RQID = l.RQID
		where h.RQCo = @poco
			And h.RecDate <= @mthcompleted
			and l.RQID not in (select l1.RQID
					from RQRL l1
					Where l1.RQCo = @poco
					and l1.Status < 5 or l1.Status > 5)	
		group by l.RQID, h.Description		
		END     
				
   
   return 0

GO
GRANT EXECUTE ON  [dbo].[vspRQHDPurgeList] TO [public]
GO
