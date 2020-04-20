SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspHRInitTrainingPlan    Script Date: 5/6/2003 11:26:25 AM ******/
    
    
    /****** Object:  Stored Procedure dbo.bspHRInitTrainingPlan    Script Date: 2/4/2003 7:40:03 AM ******/
    /****** Object:  Stored Procedure dbo.bspHRInitTrainingPlan    Script Date: 8/28/99 9:32:52 AM ******/
    CREATE   procedure [dbo].[bspHRInitTrainingPlan]
    /*************************************
    * Initializes the performance ratings group for this position
    *
    * Pass:
    *   HRCo
    *   HRRef
    *
    * Success returns:
    *	0
    *
    * Error returns:
    *	1 and error message
    **************************************/
    (@HRCo bCompany, @HRRef bHRRef, @PositionCode varchar(10) , @msg varchar(60) output)
    as
        set nocount on
        declare @rcode int
        declare @Seq int
        declare @KeyCode varchar(20)
        declare @TrainCode varchar(20)
        declare @VendorGrp int
		declare @desc bDesc
		declare @opencurs tinyint
    
    select @rcode = 0, @opencurs = 0
    
    if @HRCo is null
    begin
    	select @msg = 'Missing HR Company', @rcode = 1
    	goto bspexit
    end
    
    if @HRRef is null
    begin
    	select @msg = 'Missing Resource Number', @rcode = 1
    	goto bspexit
    end
    
    if @PositionCode is null
    begin
    	select @msg = 'Missing Position Code', @rcode = 1
    	goto bspexit
    end
    
    
	/*Get Vedor Group from HQCO*/
	select @VendorGrp = VendorGroup 
	from HQCO where
	HQCo = @HRCo

	select @Seq = isnull(max(Seq),0) 
	from HRET
	where HRCo = @HRCo and HRRef = @HRRef
--
--	select @KeyCode = min(p.TrainCode), @desc = c.Description
--	from HRPT p
--	Join HRCM c on p.HRCo = c.HRCo and p.TrainCode = c.Code and c.Type = 'T'
--	where p.HRCo = @HRCo and p.PositionCode = @PositionCode
--	Group by p.HRCo, p.TrainCode, c.Description
--
--	while @KeyCode is not null
--	begin
--		select @TrainCode = @KeyCode
--		select @Seq = @Seq+1
--
--		insert HRET (HRCo,HRRef,Seq,TrainCode,Description,Status,DegreeYN,DegreeDesc,Cost,ReimbursedYN,Instructor1099YN,VendorGroup,OSHAYN,MSHAYN,WorkRelatedYN,FirstAidYN,CPRYN)
--		values(@HRCo,@HRRef,@Seq,@TrainCode,@desc,'U','Y','',0,'N','Y',@VendorGrp,'N','N','Y','N','N')
--
--		if @@rowcount = 0
--		begin
--			select @msg = 'Error inserting Training Code',@rcode=1
--			goto bspexit
--		end
--
--		select @msg = convert(varchar(4),@Seq)
--
--		--print @msg
--		select @KeyCode = min(TrainCode), @desc = c.Description 
--		from HRPT p
--		Join HRCM c on p.HRCo = c.HRCo and p.TrainCode = c.Code and c.Type = 'T'
--		where p.HRCo=@HRCo and p.PositionCode = @PositionCode and p.TrainCode > @TrainCode
--		Group by p.HRCo, p.TrainCode, c.Description
--	end

--			declare cursPRRH cursor local fast_forward for
--			select PRCo, Crew, PostDate, SheetNum, Shift, JCCo, Job from inserted

	declare cursTrainCode cursor local fast_forward for 
	select p.TrainCode, c.Description
	from HRPT p
	Join HRCM c on p.HRCo = c.HRCo and p.TrainCode = c.Code and c.Type = 'T'
	where p.HRCo = @HRCo and p.PositionCode = @PositionCode
	Group by p.HRCo, p.TrainCode, c.Description

	open cursTrainCode

	select @opencurs = 1

	fetch next from cursTrainCode into @TrainCode, @desc

	while @@fetch_status = 0
	begin

		select @Seq = @Seq+1

		insert HRET (HRCo,HRRef,Seq,TrainCode,Description,Status,DegreeYN,DegreeDesc,Cost,ReimbursedYN,Instructor1099YN,VendorGroup,OSHAYN,MSHAYN,WorkRelatedYN,FirstAidYN,CPRYN)
		values(@HRCo,@HRRef,@Seq,@TrainCode,@desc,'U','Y','',0,'N','Y',@VendorGrp,'N','N','Y','N','N')

		if @@rowcount = 0
		begin
			select @msg = 'Error inserting Training Code',@rcode=1
			goto bspexit
		end

		fetch next from cursTrainCode into @TrainCode, @desc

	end
    
    bspexit:

		if @opencurs = 1
		begin
			close cursTrainCode
			deallocate cursTrainCode
		end

    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHRInitTrainingPlan] TO [public]
GO
