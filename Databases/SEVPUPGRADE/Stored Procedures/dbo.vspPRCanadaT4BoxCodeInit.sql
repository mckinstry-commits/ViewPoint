SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE  procedure [dbo].[vspPRCanadaT4BoxCodeInit]
/******************************************************
* CREATED BY:	MarkH 
* MODIFIED By:  MarkH 12/22/09	- Box26 AmtType should be "A"
*				EN	12/14/2010	- #142472 Box26 is setup to get Amounts from employee accums (A) but it records pensionable earnings and therefore should get Eligible earnings (E)
*				CHS	05/16/2011	- #141794 CHS added other income codes and moved 97-99
*				EN 2/10/2012 TK-12436/#145795 Box 26 (CPP Pensionable Earnings) is incorrect on T4
*
* Usage:  Provides initial master T4 Box/Code list
*	
*
* Input params:
*	
*	
*
* Output params:
*	@msg		Code description or error message
*
* Return code:
*	0 = success, 1 = failure
*******************************************************/
   
   	@prco bCompany, @taxyear char(4)
	as 
	set nocount on
	declare @rcode int
   	
	select @rcode = 0

	delete PRCAItems where PRCo = @prco and TaxYear = @taxyear

	--Boxes
	insert PRCAItems(PRCo, TaxYear, T4BoxNumber, T4BoxDescription, AmtType)
	values(@prco, @taxyear, 14, 'Employment Income', 'S') 

	insert PRCAItems(PRCo, TaxYear, T4BoxNumber, T4BoxDescription, AmtType)
	values(@prco, @taxyear, 16, 'Employee CPP Contributions', 'A') 

	insert PRCAItems(PRCo, TaxYear, T4BoxNumber, T4BoxDescription, AmtType)
	values(@prco, @taxyear, 17, 'Employee QPP Contributions', 'A') 

	insert PRCAItems(PRCo, TaxYear, T4BoxNumber, T4BoxDescription, AmtType)
	values(@prco, @taxyear, 18, 'Employee EI Premiums', 'A') 

	insert PRCAItems(PRCo, TaxYear, T4BoxNumber, T4BoxDescription, AmtType)
	values(@prco, @taxyear, 19, 'Employer''s EI Premiums', 'A') 

	insert PRCAItems(PRCo, TaxYear, T4BoxNumber, T4BoxDescription, AmtType)
	values(@prco, @taxyear, 20, 'RPP Contributions', 'A') 

	insert PRCAItems(PRCo, TaxYear, T4BoxNumber, T4BoxDescription, AmtType)
	values(@prco, @taxyear, 22, 'Income tax deducted', 'A') 

	insert PRCAItems(PRCo, TaxYear, T4BoxNumber, T4BoxDescription, AmtType)
	values(@prco, @taxyear, 24, 'EI Insurable Earnings', 'E') 

	insert PRCAItems(PRCo, TaxYear, T4BoxNumber, T4BoxDescription, AmtType)
	values(@prco, @taxyear, 26, 'CPP-QPP Pensionable Earnings', 'S') --#142472 changed from 'A' to 'E' --TK-12436/#145795 changed from 'E' to 'S'

	insert PRCAItems(PRCo, TaxYear, T4BoxNumber, T4BoxDescription, AmtType)
	values(@prco, @taxyear, 27, 'Employer''s CPP', 'A') 

	insert PRCAItems(PRCo, TaxYear, T4BoxNumber, T4BoxDescription, AmtType)
	values(@prco, @taxyear, 44, 'Union Dues', 'A') 

	insert PRCAItems(PRCo, TaxYear, T4BoxNumber, T4BoxDescription, AmtType)
	values(@prco, @taxyear, 46, 'Charitable Donations', 'A') 

	insert PRCAItems(PRCo, TaxYear, T4BoxNumber, T4BoxDescription, AmtType)
	values(@prco, @taxyear, 52, 'Pension adjustment', 'A') 

	insert PRCAItems(PRCo, TaxYear, T4BoxNumber, T4BoxDescription, AmtType)
	values(@prco, @taxyear, 55, 'Employee PPIP Premiums', 'A') 

	insert PRCAItems(PRCo, TaxYear, T4BoxNumber, T4BoxDescription, AmtType)
	values(@prco, @taxyear, 56, 'PPIP Insurable Earnings', 'A')

	--Codes	 
	insert PRCACodes(PRCo, TaxYear, T4CodeNumber, T4CodeDescription, AmtType)
	values(@prco,@taxyear,30,'Housing, board, and lodging', 'A')

	insert PRCACodes(PRCo, TaxYear, T4CodeNumber, T4CodeDescription, AmtType)
	values(@prco,@taxyear,31,'Special work site', 'A')
	
	insert PRCACodes(PRCo, TaxYear, T4CodeNumber, T4CodeDescription, AmtType)
	values(@prco,@taxyear,32,'Travel in a prescribed zone amount', 'A')

	--#141794 CHS - 5/16/11
	insert PRCACodes(PRCo, TaxYear, T4CodeNumber, T4CodeDescription, AmtType)
	values(@prco,@taxyear,33,'Medical Travel', 'A')
	--#141794 CHS - 5/16/11

	insert PRCACodes(PRCo, TaxYear, T4CodeNumber, T4CodeDescription, AmtType)
	values(@prco,@taxyear,34,'Personal use of employer''s automobile', 'A')

	insert PRCACodes(PRCo, TaxYear, T4CodeNumber, T4CodeDescription, AmtType)
	values(@prco,@taxyear,35,'Total Reasonable Per-Kilometre Allowance Amount', 'A')

	insert PRCACodes(PRCo, TaxYear, T4CodeNumber, T4CodeDescription, AmtType)
	values(@prco,@taxyear,36,'Interest-free and low-interest loan', 'A')

	insert PRCACodes(PRCo, TaxYear, T4CodeNumber, T4CodeDescription, AmtType)
	values(@prco,@taxyear,37,'Employee home-relocation loan deduction', 'A')

	insert PRCACodes(PRCo, TaxYear, T4CodeNumber, T4CodeDescription, AmtType)
	values(@prco,@taxyear,38,'Security options benefits', 'A')

	insert PRCACodes(PRCo, TaxYear, T4CodeNumber, T4CodeDescription, AmtType)
	values(@prco,@taxyear,39,'Security options deduction-110(1)(d)', 'A')

	insert PRCACodes(PRCo, TaxYear, T4CodeNumber, T4CodeDescription, AmtType)
	values(@prco,@taxyear,40,'Other taxable allowances and benefits', 'A')

	insert PRCACodes(PRCo, TaxYear, T4CodeNumber, T4CodeDescription, AmtType)
	values(@prco,@taxyear,41,'Security options deduction-110(1)(d.1)', 'A')

	insert PRCACodes(PRCo, TaxYear, T4CodeNumber, T4CodeDescription, AmtType)
	values(@prco,@taxyear,42,'Employment commissions', 'A')

	insert PRCACodes(PRCo, TaxYear, T4CodeNumber, T4CodeDescription, AmtType)
	values(@prco,@taxyear,43,'Canadian Forces personnel and police deduction', 'A')

	insert PRCACodes(PRCo, TaxYear, T4CodeNumber, T4CodeDescription, AmtType)
	values(@prco,@taxyear,53,'Deferred security option benefits', 'A')
	
	
	--BEGIN 141794 CHS - 5/16/11
	insert PRCACodes(PRCo, TaxYear, T4CodeNumber, T4CodeDescription, AmtType)
	values(@prco,@taxyear,66,'Eligible retiring allowances', 'A')	
	
	insert PRCACodes(PRCo, TaxYear, T4CodeNumber, T4CodeDescription, AmtType)
	values(@prco,@taxyear,67,'Non-eligible retiring allowances', 'A')	

	insert PRCACodes(PRCo, TaxYear, T4CodeNumber, T4CodeDescription, AmtType)
	values(@prco,@taxyear,68,'Status Indian Eligible retiring allowances', 'A')	
	
	insert PRCACodes(PRCo, TaxYear, T4CodeNumber, T4CodeDescription, AmtType)
	values(@prco,@taxyear,69,'Status Indian Non-eligible retiring allowances', 'A')		
	--END 141794 CHS - 5/16/11
	

	insert PRCACodes(PRCo, TaxYear, T4CodeNumber, T4CodeDescription, AmtType)
	values(@prco,@taxyear,70,'Municipal officer''s expense allowance', 'A')

	insert PRCACodes(PRCo, TaxYear, T4CodeNumber, T4CodeDescription, AmtType)
	values(@prco,@taxyear,71,'Status Indian employee', 'A')

	insert PRCACodes(PRCo, TaxYear, T4CodeNumber, T4CodeDescription, AmtType)
	values(@prco,@taxyear,72,'Section 122.3 income - Employment outside Canada', 'A')

	insert PRCACodes(PRCo, TaxYear, T4CodeNumber, T4CodeDescription, AmtType)
	values(@prco,@taxyear,73,'Number of days outside Canada', 'A')

	insert PRCACodes(PRCo, TaxYear, T4CodeNumber, T4CodeDescription, AmtType)
	values(@prco,@taxyear,74,'Pre-1990 past service contributions while a contributor', 'A')

	insert PRCACodes(PRCo, TaxYear, T4CodeNumber, T4CodeDescription, AmtType)
	values(@prco,@taxyear,75,'Pre-1990 past service contributions while not a contributor', 'A')

	insert PRCACodes(PRCo, TaxYear, T4CodeNumber, T4CodeDescription, AmtType)
	values(@prco,@taxyear,77,'Workers compensation benefits repaid to the employer', 'A')

	insert PRCACodes(PRCo, TaxYear, T4CodeNumber, T4CodeDescription, AmtType)
	values(@prco,@taxyear,78,'Fishers gross earnings', 'A')

	insert PRCACodes(PRCo, TaxYear, T4CodeNumber, T4CodeDescription, AmtType)
	values(@prco,@taxyear,79,'Fishers net partnership amount', 'A')

	insert PRCACodes(PRCo, TaxYear, T4CodeNumber, T4CodeDescription, AmtType)
	values(@prco,@taxyear,80,'Fishers shareperson amount', 'A')

	insert PRCACodes(PRCo, TaxYear, T4CodeNumber, T4CodeDescription, AmtType)
	values(@prco,@taxyear,81,'Placement or employment agency workers gross earnings', 'A')

	insert PRCACodes(PRCo, TaxYear, T4CodeNumber, T4CodeDescription, AmtType)
	values(@prco,@taxyear,82,'Drivers of taxis and other passenger-carrying vehicles gross earnings', 'A')

	insert PRCACodes(PRCo, TaxYear, T4CodeNumber, T4CodeDescription, AmtType)
	values(@prco,@taxyear,83,'Barbers or hairdressers gross earnings', 'A')

	insert PRCACodes(PRCo, TaxYear, T4CodeNumber, T4CodeDescription, AmtType)
	values(@prco,@taxyear,84,'Public transit pass', 'A')

	insert PRCACodes(PRCo, TaxYear, T4CodeNumber, T4CodeDescription, AmtType)
	values(@prco,@taxyear,85,'Employee-paid premiums for private health service plans', 'A')
	
	--BEGIN 141794 CHS - 5/16/11
	insert PRCACodes(PRCo, TaxYear, T4CodeNumber, T4CodeDescription, AmtType)
	values(@prco,@taxyear,86,'Stock option cash-out expense', 'A')
	--END 141794 CHS - 5/16/11

	insert PRCACodes(PRCo, TaxYear, T4CodeNumber, T4CodeDescription, AmtType)
	values(@prco,@taxyear,97,'Stock option benefit amount before February 28, 2000', 'A')

	insert PRCACodes(PRCo, TaxYear, T4CodeNumber, T4CodeDescription, AmtType)
	values(@prco,@taxyear,98,'Stock option and share deduction 110(1)(d) amount before February 28, 2000', 'A')
	
	insert PRCACodes(PRCo, TaxYear, T4CodeNumber, T4CodeDescription, AmtType)
	values(@prco,@taxyear,99,'Stock option and share deduction 110(1)(d.1) amount before February 28, 2000', 'A')

	vspexit:
	return @rcode



GO
GRANT EXECUTE ON  [dbo].[vspPRCanadaT4BoxCodeInit] TO [public]
GO
