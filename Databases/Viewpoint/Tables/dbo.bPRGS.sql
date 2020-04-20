CREATE TABLE [dbo].[bPRGS]
(
[PRCo] [dbo].[bCompany] NOT NULL,
[PRGroup] [dbo].[bGroup] NOT NULL,
[VPUserName] [dbo].[bVPUserName] NOT NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biPRGS] ON [dbo].[bPRGS] ([PRCo], [PRGroup], [VPUserName]) WITH (FILLFACTOR=90) ON [PRIMARY]

CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bPRGS] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   

CREATE trigger [dbo].[btPRGSd] on [dbo].[bPRGS] for DELETE as
/*-----------------------------------------------------------------
* Created: EN 2/7/00
* Modified:	EN 02/18/03 - issue 23061  added isnull check, and dbo
			mh 4/14/04 - Issue 22628 - Need to delete security entries
*						for HRRefs who have a PR Employee number specified but
*						have not been interfaced to PR.	
*			EN 11/19/04 - issue 26174  added auditing to bPRGS
*			GG 03/12/08 - #127328 - fix removal of data security entries for HRRM employees not setup in PR, remove pseudo cursor
*
*/----------------------------------------------------------------
declare @errmsg varchar(255), @numrows int
declare @prco bCompany, @vpusername bVPUserName, @prgroup bGroup

select @numrows = @@rowcount
if @numrows = 0 return
set nocount on
   	
   	
-- remove data security entries for all Employees in the deleted PR Company, PR Group, and User combinations
-- assigned in PR.
delete dbo.vDDDU
from deleted d 
join dbo.vDDDU u on u.Datatype = 'bEmployee' and u.Qualifier = d.PRCo and u.VPUserName = d.VPUserName
	and u.Employee in (select e.Employee from dbo.bPREH e where e.PRCo = d.PRCo and e.PRGroup = d.PRGroup)
						
						
-- remove data security entries for all Employees in the deleted PR Company, PR Group, and User combinations
-- assigned through HR.  These Employee #s may not exist in bPREH
delete dbo.vDDDU
from deleted d 
join dbo.vDDDU u on u.Datatype = 'bEmployee' and u.Qualifier = d.PRCo and u.VPUserName = d.VPUserName
	and u.Employee in (select h.PREmp from dbo.bHRRM h where h.PRCo = d.PRCo and h.PRGroup = d.PRGroup
							and h.PREmp is not null)
			
   
--   	/* delete vDDDU entries for PR group security */
--   	select @prco = min(PRCo) from deleted
--   
--   	while @prco is not null
--   	begin
--   
--   		select @prgroup = min(PRGroup) from deleted where PRCo = @prco
--   
--   		while @prgroup is not null
--   		begin
--           	select @vpusername = min(VPUserName) from deleted where PRCo = @prco and PRGroup = @prgroup
--   
--   	        while @vpusername is not null
--       	    begin
--   
--   			    delete from dbo.vDDDU
--   			    where Datatype = 'bEmployee' and Qualifier = @prco
--   				and Instance in (select convert(char(30),Employee) from dbo.bPREH
--   				where PRCo = @prco and PRGroup = @prgroup)
--   			    and VPUserName = @vpusername
--   
--   				--Need to check HRRM
--   				delete from dbo.vDDDU
--   				where Datatype = 'bEmployee' and Qualifier = @prco
--   				and Instance in (select convert(char(30), PREmp) from dbo.bHRRM
--   				where PRCo = @prco and PRGroup = @prgroup and PREmp is not null
--   				and ExistsInPR = 'N')
--   				and VPUserName = @vpusername
--   
--   				select @vpusername = min(VPUserName) from deleted where PRCo = @prco and PRGroup = @prgroup and VPUserName > @vpusername
--   			end
--   
--   			select @prgroup = min(PRGroup) from deleted where PRCo = @prco and PRGroup > @prgroup
--   		end
--   
--   		select @prco = min(PRCo) from deleted where PRCo > @prco
--   	end
   
   --issue 26174  audit deletions to bHQMA
   insert into dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bPRGS', ' PRGroup: ' + convert(varchar(3),PRGroup) + ' VPUserName: ' + VPUserName,
   	PRCo, 'D', null, null, null, getdate(), SUSER_SNAME() from deleted
   	
   
   return
   error:
    	select @errmsg = isnull(@errmsg,'') + ' - cannot delete PR Group Security!'
        	RAISERROR(@errmsg, 11, -1);
        	rollback transaction
    
   
   
   
   
   
   
   
   
   
   
  
 




GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   
   /****** Object:  Trigger dbo.btPRGSi    Script Date: 2/7/00 12:04:11 PM ******/
   CREATE    trigger [dbo].[btPRGSi] on [dbo].[bPRGS] for INSERT as
   

/*-----------------------------------------------------------------
    *   	Created by: EN 2/7/00
    * 	Modified by: GG 02/28/00 - fixed join between inserted and bPREH in Security update
    *				 GF 06/12/03 - changed from pseudo cursor to cursor for bulk inserts
    *				EN 02/18/03 - issue 23061  added isnull check, with (nolock), and dbo
    *											and corrected old syle joins
    *				EN 11/19/04 - issue 26174  added auditing to bPRGS
    *
    *	This trigger rejects insertion in bPRGS (PR Group Security)
    *	if the following error condition exists:
    *
    *	PR Company is invalid.
    *	PR Group is invalid.
    *	VPUserName is invalid.
    */----------------------------------------------------------------
   declare @errmsg varchar(255), @numrows int, @validcnt int, @opencursor int
   declare @prco bCompany, @prgroup bGroup, @vpusername bVPUserName
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   set @opencursor = 0
   
   /* validate PR Company */
   select @validcnt = count(*) from dbo.bHQCO c with (nolock) join inserted i on c.HQCo = i.PRCo
   if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Invalid Company #'
   	goto error
   	end
   
   /* validate PR Group */
   select @validcnt = count(*) from dbo.bPRGR c with (nolock) join inserted i on c.PRCo = i.PRCo
   	and c.PRGroup = i.PRGroup
   if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Invalid Group'
   	goto error
   	end
   
   /* validate VPUserName */
   select @validcnt = count(*) from dbo.vDDUP c with (nolock) join inserted i on c.VPUserName = i.VPUserName
   if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Invalid user name'
   	goto error
   	end
   
   -- add vDDDU entries for PR group security
   -- create a cursor to process PR Group Security
   declare bcPRGS cursor FAST_FORWARD
   for select PRCo, PRGroup, VPUserName
   from inserted
   Order By PRCo, PRGroup, VPUserName
   
   -- open cursor
   open bcPRGS
   select @opencursor = 1
   
   -- loop through bcPRGS cursor
   PRGS_loop:
   fetch next from bcPRGS into @prco, @prgroup, @vpusername
   
   if @@fetch_status <> 0 goto PRGS_end
   
   
   -- insert vDDDU record from bPREH
   insert into dbo.vDDDU (Datatype, Qualifier, Instance, VPUserName)
   select 'bEmployee', @prco, convert(char(30),e.Employee), @vpusername
   from dbo.bPREH e with (nolock)
   where e.PRCo = @prco and e.PRGroup = @prgroup
   and not exists (select * from dbo.vDDDU u with (nolock) where u.Datatype = 'bEmployee' 
   				and u.Qualifier = @prco and u.Instance = convert(char(30),e.Employee) 
   				and u.VPUserName = @vpusername)
   
   
   -- insert vDDDU record from bHRRM
   insert into dbo.vDDDU (Datatype, Qualifier, Instance, VPUserName)
   select 'bEmployee',@prco, convert(char(30),m.PREmp),@vpusername
   from dbo.bHRRM m with (nolock)
   where m.PRCo = @prco and m.PRGroup = @prgroup and m.PREmp is not null
   and not exists(select * from dbo.vDDDU u with (nolock) where u.Datatype = 'bEmployee' 
   				and u.Qualifier = @prco and u.Instance = convert(char(30),m.PREmp)
     				and u.VPUserName = @vpusername)
   and not exists(select * from dbo.bPREH h with(nolock) where h.PRCo = @prco and h.Employee = m.PREmp)
   
   goto PRGS_loop
   
   
   PRGS_end:
   	if @opencursor = 1
   	    begin
   	    close bcPRGS
   	    deallocate bcPRGS
   	    select @opencursor = 0
   	    end
   
   --issue 26174  audit insertions to bHQMA
   insert into dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bPRGS', ' PRGroup: ' + convert(varchar(3),PRGroup) + ' VPUserName: ' + VPUserName,
   	PRCo, 'A', null, null, null, getdate(), SUSER_SNAME() from inserted
   
   
   
   return
   
   
   error:
   	if @opencursor = 1
   	    begin
   	    close bcPRGS
   	    deallocate bcPRGS
   	    select @opencursor = 0
   	    end
   
   	select @errmsg = isnull(@errmsg,'') + ' - cannot insert PR Group Security!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
   
  
 




GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   /****** Object:  Trigger dbo.btPRGSu    Script Date: 2/7/00 04:08:12 PM ******/
   CREATE  trigger [dbo].[btPRGSu] on [dbo].[bPRGS] for UPDATE as
    

declare @errmsg varchar(255), @numrows int, @validcnt int
    /*-----------------------------------------------------------------
     * Created by: EN 2/7/00
     * Modified by:	EN 02/18/03 - issue 23061  added isnull check and corrected old syle joins
     *
     *	This trigger rejects update in bPRGS (PR Group Security) if the
     *	following error condition exists:
     *
     *	Primary key changed.
     */----------------------------------------------------------------
    select @numrows = @@rowcount
    if @numrows = 0 return
    set nocount on
   
    /* check for key changes */
    select @validcnt = count(*) from deleted d join inserted i
    	on d.PRCo = i.PRCo and d.PRGroup = i.PRGroup and d.VPUserName = i.VPUserName
    if @validcnt <> @numrows
    	begin
    	select @errmsg = 'Cannot change PR Company, PR Group or user name '
    	goto error
    	end
   
   
    return
    error:
    	select @errmsg = isnull(@errmsg,'') + ' - cannot update PR Group Security!'
    	RAISERROR(@errmsg, 11, -1);
    	rollback transaction
   
   
   
   
   
   
  
 



GO
