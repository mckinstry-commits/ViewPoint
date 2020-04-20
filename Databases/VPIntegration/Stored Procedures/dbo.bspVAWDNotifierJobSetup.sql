SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [dbo].[bspVAWDNotifierJobSetup]  
   /***********************************************************  
   * CREATED BY: TV  09/26/01  
   * MODIFIED By:TV - 23061 added isnulls  
   * JonathanP 01/30/07 - Updated the procedure to use job_id and schedule_id  
   *       instead of job_name and schedule_name. See issue #126861  
   * CC 09/04/2008 - Issue #129700 Increase length of @databasename to 128  
   * DC 12/4/2009 - Issue #136767. If Updating Job with no schedule id, create schedule id
   *     
   *  
   * USAGE:  Sets up SQLServer Job and JobStep necessary for a Notifier event  
   *  
   * Returns error and errmsg if  
   *  
   *  
   * Returns success and errmsg (ie warning) if  
   *  
   *  
   * INPUT PARAMETERS  
   * See below  
   *   
   * OUTPUT PARAMETERS  
   * JobID and Error Message if applicable  
   *  
   * RETURN VALUE  
   * 0 - Success  
   * 1 - Failure  
   * 2 - Warning  
    *****************************************************/  
   (@job_name sysname,   
   @enabled int,   
   @description varchar(512),  
   @ADU_status char(1),  
   @old_job_name varchar(50) = null,   
   @stdproc varchar (250),   
   @co Varchar(3),   
   @freq_type char(3),  
   @freq_interval char(3),   
   @freq_subday_type char(3),   
   @freq_subday_interval char(3),   
   @freq_relative_interval char(3),  
   @freq_recurrence_factor char(3),   
   @active_start_date varchar(15),   
   @active_end_date varchar(15),   
   @active_start_time varchar(15),  
   @active_end_time varchar(15),   
   @databasename varchar(128),   
   @job_id uniqueidentifier output,  
   @msg Varchar(255) output)   
     
   as   
     
     
   set nocount on  
     
   declare @rcode int, @operator sysname  
   DECLARE @schedule_id int  
   select @operator =isnull((select name from msdb.dbo.sysoperators where name = 'Notifier' and isnull(email_address, '') <> ''),'')  
   select @rcode = 1  
     
   --If you are adding a job  
   if @ADU_status = 'A'  
       begin  
       createjob:  
         
       --Add the job     
       exec msdb.dbo.sp_add_job @job_name =  @job_name,  
                                @enabled = @enabled,  
                                @description =  @description,    
                                @start_step_id  = '1',   
                                @notify_level_eventlog = '0',   
                                @notify_level_email = '2',    --this adds notification if procedure fails  
                                @notify_email_operator_name  = @operator,  
                                @job_id = @job_id output  
     
       if @@error <> 0  
           begin  
           select @msg = 'Error adding job.'  
           goto bspexit  
           end  
     
        
       --Add the job step  
       exec msdb.dbo.sp_add_jobstep @job_id = @job_id,  
                                    @step_id = '1',   
                                    @step_name = @job_name,    
                                    @command = @stdproc,   
                                    @additional_parameters = @co,  
                                    @on_fail_action = '2',  
                                    @database_name = @databasename  
         
       if @@error <> 0   
           begin  
           select @msg = 'Error adding job step.'  
           goto bspexit  
           end  
       
       
       -- Add the Job Sched  
       exec msdb.dbo.sp_add_schedule @schedule_name = @job_name, -- The schedule name will be the same as the job name for now, since we are only supporting 1 schedule per job at the moment.                      
          @enabled = @enabled,  
                            @freq_type = @freq_type,   
                            @freq_interval = @freq_interval,  
                            @freq_subday_type = @freq_subday_type,  
                            @freq_subday_interval = @freq_subday_interval,  
                            @freq_relative_interval = @freq_relative_interval,  
                            @freq_recurrence_factor = @freq_recurrence_factor,  
                            @active_start_date = @active_start_date,  
                            @active_end_date = @active_end_date,  
                            @active_start_time = @active_start_time,  
                            @active_end_time = @active_end_time,  
                            @schedule_id = @schedule_id output  
                              
                                     
       if @@error <> 0  
           begin  
           select @msg = 'Error adding schedule.'  
           goto bspexit  
           end  
        
      -- Attach the schedule to the job.  
      EXEC msdb.dbo.sp_attach_schedule @job_id = @job_id,  
            @schedule_id = @schedule_id -- This needs to be changed, but for 6.0.1, the schedule name will match the job name since there will only be 1 schedule per job.  
                          
     
       --Add target Server  
       exec msdb.dbo.sp_add_jobserver  @job_name = @job_name,  
                                       @server_name  = '(LOCAL)'  
       if @@error <> 0  
           begin  
           select @msg = 'Error adding target Server.'  
           goto bspexit  
           END
       end  
     
     
     
   -- IF you are updating a Job  
     
     
   if @ADU_status = 'U'  
       begin  
       -- Make sure the job exists. If not, create it.  
       if not exists(select * from msdb.dbo.sysjobs where name = @job_name)  
           begin  
           goto createjob  
           end  
     
       SELECT top 1 @job_id = job_id   
       FROM msdb.dbo.[sysjobs]  
       WHERE [name] = @job_name  
     
       --Update job  
        exec msdb.dbo.sp_update_job @job_id =  @job_id,  
                                @enabled = @enabled,  
                                @description =  @description,    
                                @start_step_id  = '1',   
                                @notify_level_eventlog = '0',   
                                @notify_level_email = '2',    --this adds notification if procedure fails  
                                @notify_email_operator_name  = @operator  
     
       if @@error <> 0  
           begin  
           select @msg = 'Error updating job.'  
           goto bspexit  
           end  
     
        
       --Add the job step  
       exec msdb.dbo.sp_update_jobstep @job_id = @job_id,   
                                    @step_id = '1',   
                                    @step_name = @job_name,    
                                    @command = @stdproc,   
                                    @additional_parameters = @co,  
                                    @on_fail_action = '2',  
                                    @database_name = @databasename  
         
       if @@error <> 0   
           begin  
           select @msg = 'Error updating job step.'  
           goto bspexit  
           end           
        
    SELECT top 1 @schedule_id = schedule_id   
       FROM msdb.dbo.[sysjobschedules]  
       WHERE job_id = @job_id
       
       IF @schedule_id IS NULL
       BEGIN
       	   -- Add the Job Sched  
		   exec msdb.dbo.sp_add_schedule @schedule_name = @job_name, -- The schedule name will be the same as the job name for now, since we are only supporting 1 schedule per job at the moment.                      
			  @enabled = @enabled,  
								@freq_type = @freq_type,   
								@freq_interval = @freq_interval,  
								@freq_subday_type = @freq_subday_type,  
								@freq_subday_interval = @freq_subday_interval,  
								@freq_relative_interval = @freq_relative_interval,  
								@freq_recurrence_factor = @freq_recurrence_factor,  
								@active_start_date = @active_start_date,  
								@active_end_date = @active_end_date,  
								@active_start_time = @active_start_time,  
								@active_end_time = @active_end_time,  
								@schedule_id = @schedule_id output  
	                              
	                                     
		   if @@error <> 0  
			   begin  
			   select @msg = 'Error adding schedule.'  
			   goto bspexit  
			   END
			   
			-- Attach the schedule to the job.  
		  EXEC msdb.dbo.sp_attach_schedule @job_id = @job_id,  
				@schedule_id = @schedule_id -- This needs to be changed, but for 6.0.1, the schedule name will match the job name since there will only be 1 schedule per job.  
       END
		
       -- Add the Job Sched  
       exec msdb.dbo.sp_update_schedule @schedule_id = @schedule_id,  
          @new_name = @job_name,  
             @enabled = @enabled,  
          @freq_type = @freq_type,   
          @freq_interval = @freq_interval,  
             @freq_subday_type = @freq_subday_type,  
             @freq_subday_interval = @freq_subday_interval,  
          @freq_relative_interval = @freq_relative_interval,  
          @freq_recurrence_factor = @freq_recurrence_factor,  
          @active_start_date = @active_start_date,  
          @active_end_date = @active_end_date,  
          @active_start_time = @active_start_time,  
          @active_end_time = @active_end_time  
         
       if @@error <> 0  
           begin  
           select @msg = 'Error updating job.'  
           goto bspexit  
           end  
       end  
     
   --If you are deleting a job  
   if @ADU_status = 'D'  
       begin  
       --delete Job  
       exec msdb.dbo.sp_delete_job @job_name = @job_name  
     
       if @@error <> 0  
           begin  
           select @msg = 'Error deleteing job'  
           goto bspexit  
           END
       end  
     
     
   bspexit:  
   Select @rcode = @@error  
   return @rcode  
GO
GRANT EXECUTE ON  [dbo].[bspVAWDNotifierJobSetup] TO [public]
GO
