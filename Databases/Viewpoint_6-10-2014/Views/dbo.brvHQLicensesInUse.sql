SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[brvHQLicensesInUse]
    as
    select distinct AcctPM=case when upper(program_name)='PM' then 'PM' else 'Acct' end,
                     Program=convert(varchar(10),upper(program_name)),
                    HostName=convert(varchar(30),rtrim(hostname)),Login=convert(varchar(30),rtrim(loginame))
      from master..sysprocesses p 
     where loginame <> 'bidtek'  
    and upper(program_name) in
     ('AP', 'AR', 'CM', 'EM', 'IN', 'GL', 'HR', 'JB', 'JC', 'MS', 'PO', 'PR', 'RP', 'SL', 'IM','PM')

GO
GRANT SELECT ON  [dbo].[brvHQLicensesInUse] TO [public]
GRANT INSERT ON  [dbo].[brvHQLicensesInUse] TO [public]
GRANT DELETE ON  [dbo].[brvHQLicensesInUse] TO [public]
GRANT UPDATE ON  [dbo].[brvHQLicensesInUse] TO [public]
GRANT SELECT ON  [dbo].[brvHQLicensesInUse] TO [Viewpoint]
GRANT INSERT ON  [dbo].[brvHQLicensesInUse] TO [Viewpoint]
GRANT DELETE ON  [dbo].[brvHQLicensesInUse] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[brvHQLicensesInUse] TO [Viewpoint]
GO
