SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  procedure [dbo].[bspPRProcessEmplEFT]
 /***********************************************************
 * CREATED BY:		CHS 10/12/2012
 * MODIFIED BY:
 *
 * USAGE:
 * Generates Direct Deposit distibutions IF Employee Pay Seq to be paid by EFT.
 *
 * INPUT PARAMETERS
 *   @prco	    PR Company
 *   @prgroup	PR Group
 *   @prenddate	PR Ending Date
 *   @employee	Employee to process
 *   @payseq	Payment Sequence #
 *   @posttoall earnings posted to all days in Pay Period - Y or N
 *
 * OUTPUT PARAMETERS
 *   @errmsg  	Error message IF something went wrong
 *
 * RETURN VALUE
 *   0   success
 *   1   fail
 *****************************************************/
	@prco bCompany, @prgroup bGroup, @prenddate bDate, @employee bEmployee, 
	@payseq tinyint, @errmsg varchar(255) output
 
	AS
	SET NOCOUNT ON
 
	DECLARE @rcode int 

	-- Direct Depost variables
	DECLARE @earns bDollar, @dedns bDollar, @netpay bDollar, @routingid varchar(10), @bankacct varchar(20), @seq tinyint,
	@ddtype char(1), @ddmethod char(1), @ddpct bPct, @ddamt bDollar, @dsseq tinyint, @dsamt bDollar, @amtdist bDollar

	SELECT @rcode = 0

	--cursor flags
	DECLARE @openDirDep tinyint
 
 
	-- Process Direct Deposit distributions IF Employee/Pay Seq to be paid by EFT
	IF EXISTS(SELECT * 
				FROM dbo.bPRSQ WITH (NOLOCK)
				WHERE PRCo = @prco 
					AND PRGroup = @prgroup 
					AND PREndDate = @prenddate
					AND Employee = @employee 
					AND PaySeq = @payseq 
					AND PayMethod = 'E')
		BEGIN
		-- make sure Employee is setup for EFT
		IF not EXISTS(SELECT * FROM dbo.bPREH WITH (NOLOCK) WHERE PRCo = @prco AND Employee = @employee AND DirDeposit = 'A')
			BEGIN
			SELECT @errmsg = 'Employee ' + convert(varchar(6),@employee) + ' is not setup WITH Active EFT information - unable to create Direct Deposit distribution.', @rcode = 1
			GOTO bspexit
			END
			
		-- get net pay
		SELECT @earns = isnull(sum(Amount),0.00)
		FROM dbo.bPRDT WITH (NOLOCK)
		WHERE PRCo = @prco 
			AND PRGroup = @prgroup 
			AND PREndDate = @prenddate 
			AND Employee = @employee
			AND PaySeq = @payseq 
			AND EDLType = 'E'


		SELECT @dedns = ISNULL(SUM(CASE UseOver 
										WHEN 'Y' 
										THEN OverAmt 
										ELSE Amount 
										END),0.00)
						+ ISNULL(SUM(CASE 
										WHEN PaybackOverYN='Y' 
										THEN PaybackOverAmt 
										ELSE PaybackAmt 
										END),0.00)
		FROM dbo.bPRDT WITH (NOLOCK)
		WHERE PRCo = @prco 
			AND PRGroup = @prgroup 
			AND PREndDate = @prenddate 
			AND Employee = @employee
			AND PaySeq = @payseq 
			AND EDLType = 'D'

		SELECT @netpay = @earns - @dedns
		
		IF @netpay <= 0.00 
			BEGIN
			GOTO bspexit
			END

		-- cursor on Deposit Distribution
		DECLARE bcDirDep CURSOR FOR
		SELECT distinct d.Seq, d.RoutingId, d.BankAcct, d.Type, d.Method, d.Pct, d.Amount
		FROM dbo.bPRDD d WITH (NOLOCK)
			JOIN dbo.bPRAF f WITH (NOLOCK) on f.PRCo = d.PRCo AND f.Frequency = d.Frequency
		WHERE d.PRCo = @prco 
			AND f.PRGroup = @prgroup 
			AND f.PREndDate = @prenddate 
			AND	d.Employee = @employee 
			AND d.Status = 'A'
		ORDER BY d.Seq

		OPEN bcDirDep
		SELECT @openDirDep = 1, @amtdist = 0.00, @dsseq = 1

		-- loop through Employee DL cursor
		next_DirDep:
		FETCH NEXT FROM bcDirDep 
		INTO @seq, @routingid, @bankacct, @ddtype, @ddmethod, @ddpct, @ddamt
		IF @@fetch_status = -1 GOTO end_DirDep
		IF @@fetch_status <> 0 GOTO next_DirDep

		-- process each direct deposit dist
		SELECT @dsamt = 0.00

		IF @ddmethod = 'A' SELECT @dsamt = @ddamt
		IF @ddmethod = 'P' SELECT @dsamt = @ddpct * @netpay

		IF @amtdist + @dsamt > @netpay SELECT @dsamt = @netpay - @amtdist
		IF @dsamt = 0.00 GOTO next_DirDep

		-- insert Direct Deposit Sequence
		INSERT dbo.bPRDS (PRCo, PRGroup, PREndDate, Employee, PaySeq, DistSeq, RoutingId, BankAcct, Type, Amt)
		VALUES (@prco, @prgroup, @prenddate, @employee, @payseq, @dsseq, @routingid, @bankacct, @ddtype, @dsamt)
		IF @@rowcount <> 1
			BEGIN
			SELECT @errmsg = 'Unable to update Direct Deposit distribution. Seq# ' + convert(varchar(3),@dsseq), @rcode = 1
			GOTO bspexit
			END
			
		SELECT @amtdist = @amtdist + @dsamt, @dsseq = @dsseq + 1
		GOTO next_DirDep 

		end_DirDep:
		CLOSE bcDirDep
		DEALLOCATE bcDirDep
		SELECT @openDirDep = 0

		-- update remaining net pay into Employee's default account
		IF @amtdist <> @netpay
			BEGIN
			-- insert Direct Deposit Sequence
			INSERT dbo.bPRDS 
				(PRCo, PRGroup, PREndDate, Employee, PaySeq, DistSeq, RoutingId, BankAcct, Type, Amt)
			SELECT 
				@prco, @prgroup, @prenddate, @employee, @payseq, @dsseq, e.RoutingId, e.BankAcct, e.AcctType, (@netpay - @amtdist)
			FROM dbo.bPREH e WITH (NOLOCK)
			WHERE e.PRCo = @prco 
				AND e.Employee = @employee
			IF @@rowcount <> 1
				BEGIN
				SELECT @errmsg = 'Unable to update final Direct Deposit distribution. Seq# ' + convert(varchar(3),@dsseq), @rcode = 1
				GOTO bspexit
				END
				
			END
			
		END
	 
 bspexit:

 IF @openDirDep = 1
	BEGIN
	CLOSE bcDirDep
	DEALLOCATE bcDirDep
	END
 
 	RETURN @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRProcessEmplEFT] TO [public]
GO
