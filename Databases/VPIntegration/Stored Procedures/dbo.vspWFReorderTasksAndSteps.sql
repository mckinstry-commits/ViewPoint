SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspWFReorderTasksAndSteps]
/************************************************************
* CREATED:     8/14/2009 Dave C
* MODIFIED:    
*
* USAGE:
*	Reorders the task number in vWFVPTemplateTasks and vWFTemplateTasksc
*	in order to make the numbers contiguous after a record delete, as well as
*	updating vWFVPTemplateSteps and vWFTemplateStepsc so that they also reflect the correct
*	task number.
*
*	This sp also reorders any step records in vWFVPTemplateSteps and vWFTemplateStepsc after
*	a record delete, so that steps will also be contiguous.
*	
*
* CALLED FROM:
*	Viewpoint frmWFChecklistTemplate
*
* INPUT PARAMETERS
*   @template AS VARCHAR(20), @task AS int 
*   
************************************************************/
(
	@template AS VARCHAR(20), @task AS int
)
AS
	SET NOCOUNT OFF;
	
--Temp table to hold the current and ordered tasks
DECLARE @OriginalValues TABLE(CurrentValue INT,
							  OrderedValue INT)

--Populate table with current values for vWFTemplateTasksc
INSERT INTO @OriginalValues (CurrentValue, OrderedValue)
	SELECT
		Task, ROW_NUMBER() OVER (ORDER BY Task) AS OrderedTask
	FROM
		dbo.vWFTemplateTasksc
	WHERE
		Template = @template
		
		
		
--Update vWFTemplateTasksc
UPDATE
	dbo.vWFTemplateTasksc
SET
	Task = Ordered.OrderedValue
FROM
	dbo.vWFTemplateTasksc BeforeOrdered INNER JOIN @OriginalValues Ordered
	ON BeforeOrdered.Task = Ordered.CurrentValue
WHERE Template = @template

--Update vWFTemplateStepsc with the correct Task Number

UPDATE
	dbo.vWFTemplateStepsc
SET
	Task = Ordered.OrderedValue
FROM
	dbo.vWFTemplateStepsc BeforeOrdered INNER JOIN @OriginalValues Ordered
	ON BeforeOrdered.Task = Ordered.CurrentValue
WHERE Template = @template



--Clear the temporary table to process the non-custom Task and Step tables
DELETE FROM @OriginalValues

--Populate table with current values for vWFVPTemplateTasks
INSERT INTO @OriginalValues (CurrentValue, OrderedValue)
	SELECT
		Task, ROW_NUMBER() OVER (ORDER BY Task) AS OrderedTask
	FROM
		dbo.vWFVPTemplateTasks
	WHERE
		Template = @template
		
		

--Update vWFVPTemplateTasks
UPDATE
	dbo.vWFVPTemplateTasks
SET
	Task = Ordered.OrderedValue
FROM
	dbo.vWFVPTemplateTasks BeforeOrdered INNER JOIN @OriginalValues Ordered
	ON BeforeOrdered.Task = Ordered.CurrentValue
WHERE Template = @template

--Update vWFVPTemplateSteps with the correct Task Number
UPDATE
	dbo.vWFVPTemplateSteps
SET
	Task = Ordered.OrderedValue
FROM
	dbo.vWFVPTemplateSteps BeforeOrdered INNER JOIN @OriginalValues Ordered
	ON BeforeOrdered.Task = Ordered.CurrentValue
WHERE Template = @template





--Clear table again to update steps
DELETE FROM @OriginalValues

--Populate table with current values for vWFTemplateStepsc
INSERT INTO @OriginalValues (CurrentValue, OrderedValue)
	SELECT
		Step, ROW_NUMBER() OVER (ORDER BY Task) AS OrderedTask
	FROM
		dbo.vWFTemplateStepsc
	WHERE
		Template = @template AND Task = @task
		
--vWFTemplateStepsc with the correct step values for the given task and template
UPDATE
	dbo.vWFTemplateStepsc
SET
	Step = Ordered.OrderedValue
FROM
	dbo.vWFTemplateStepsc BeforeOrdered INNER JOIN @OriginalValues Ordered
	ON BeforeOrdered.Step = Ordered.CurrentValue
WHERE Template = @template AND Task = @task


----Clear the temporary table to process the non-custom Step changes
DELETE FROM @OriginalValues


--Populate table with current values for vWFTemplateStepsc
INSERT INTO @OriginalValues (CurrentValue, OrderedValue)
	SELECT
		Step, ROW_NUMBER() OVER (ORDER BY Task) AS OrderedTask
	FROM
		dbo.vWFVPTemplateSteps
	WHERE
		Template = @template AND Task = @task
		
--vWFTemplateStepsc with the correct step values for the given task and template
UPDATE
	dbo.vWFVPTemplateSteps
SET
	Step = Ordered.OrderedValue
FROM
	dbo.vWFVPTemplateSteps BeforeOrdered INNER JOIN @OriginalValues Ordered
	ON BeforeOrdered.Step = Ordered.CurrentValue
WHERE Template = @template AND Task = @task
GO
GRANT EXECUTE ON  [dbo].[vspWFReorderTasksAndSteps] TO [public]
GO
