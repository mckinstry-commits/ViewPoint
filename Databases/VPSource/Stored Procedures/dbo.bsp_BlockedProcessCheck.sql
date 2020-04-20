SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[bsp_BlockedProcessCheck]
    /****************************************************
     * Created:  GG 09/13/01
     * Modified:
     *
     * Usage:
     *	Identifies connections with open transactions or those blocking other processes
     *
     * Status Definitions, per Books Online:
     * Background	SPID is performing a background task. 
     * Sleeping		SPID is not currently executing. This usually indicates that the SPID is awaiting a command from the application. 
     * Runnable		SPID is currently executing. 
     * Dormant  	Same as Sleeping, except Dormant also indicates that the SPID has been reset after completing an RPC event. The reset cleans up resources used during the RPC event. This is a normal state and the SPID is available and waiting to execute further commands.  
     * Rollback		The SPID is in rollback of a transaction. 
     * Defwakeup	Indicates that a SPID is waiting on a resource that is in the process of being freed. The waitresource field should indicate the resource in question. 
     * Spinloop		Process is waiting while attempting to acquire a spinlock used for concurrency control on SMP systems 
     *
     **********************************************************/
    as
    
    set nocount on
    
    -- build temp table to hold process info
    create table #ProcCheck(
    	Loginame varchar(120) null,
    	Status varchar(50) null ,
    	SPID int null,
    	CPU int null,
    	Pys_IO int null,
    	WaitTime int null,
    	BlockSPID int null,
    	LastCmd varchar(500) null,
    	HostName varchar(36) null,
    	ProgName varchar(100) null,
    	NTUser varchar(50) null,
    	LoginTime datetime null,
    	LastBatch datetime null,
    	OpenTrans int null)
    
    create table #ProcInfo(
    	EventType varchar(100) null,
    	Parameters int null,
    	EventInfo varchar(7000) null
    )
    
    INSERT INTO #ProcCheck(Loginame, Status, SPID, CPU, Pys_IO, WaitTime, BlockSPID, HostName, 
    	ProgName, NTUser, LoginTime, LastBatch, OpenTrans)
    SELECT loginame, status, spid, cpu, physical_io, waittime, blocked, SUBSTRING(hostname, 1, 36),
    	SUBSTRING(program_name, 1, 100), SUBSTRING(nt_username, 1, 50), login_time, last_batch,
    	open_tran
    FROM master..sysprocesses
    where (blocked > 0
    or spid in (select blocked from master..sysprocesses (NOLOCK) where blocked > 0)
    or open_tran > 0)
    and spid <> @@SPID
    
    declare @spid int ,	@cmd varchar(7000)
    
    -- use a cursor to identify each process id
    declare Procs cursor fast_forward for
    SELECT SPID FROM #ProcCheck
    
    OPEN Procs
    
    FETCH NEXT FROM Procs INTO @spid
    WHILE @@FETCH_STATUS = 0
    	BEGIN
    
    	SET @cmd = 'DBCC INPUTBUFFER(' + CONVERT(varchar, @spid) + ')'
    
    	INSERT INTO #ProcInfo
    	EXEC(@cmd)
    	
    	SELECT @cmd = EventInfo
    	FROM #ProcInfo
    
    	DELETE FROM #ProcInfo
    
    	UPDATE #ProcCheck
    	SET LastCmd = SUBSTRING(@cmd, 1, 500)
    	WHERE SPID = @spid
    
    	FETCH NEXT FROM Procs INTO @spid
    
    	END
    
    CLOSE Procs
    DEALLOCATE Procs
    
    SELECT * FROM #ProcCheck	
    
    DROP TABLE #ProcCheck
    DROP TABLE #ProcInfo
    
    return

GO
GRANT EXECUTE ON  [dbo].[bsp_BlockedProcessCheck] TO [public]
GO
