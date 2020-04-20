using Microsoft.VisualBasic;
using System.IO;
using BaseClasses.Data;
using Ciloci.Flee;
using POViewer.UI;
using System;
using POViewer.Data;

namespace POViewer
{

    /// <summary>
    /// The FormulaEvaluator class evaluates a formula passed to the Evaluate function.
    /// You must set the DataSource and Page variables as part of this.
    /// </summary>
    /// <remarks></remarks>
    public class FormulaEvaluator:BaseFormulaEvaluator
    {



        /// <summary>
        /// Record control (or row) from which this evaluator is called.  Could be Nothing
        /// if called from the data access layer.
        /// </summary>
        private System.Web.UI.Control _callingControl = null;
        public System.Web.UI.Control CallingControl
        {
            get { return _callingControl; }
            set { _callingControl = value; }
        }

        /// <summary>
        /// Create a new evaluator and prepare for evaluation.
        /// </summary>
        public FormulaEvaluator()
        {

            _evaluator = new ExpressionContext();

            // The order of adding types is important. First we add our own
            // formula functions, followed by the generic types.

            Evaluator.Imports.AddType(typeof(FormulaUtils));
            Evaluator.Imports.AddType(typeof(BaseFormulaUtils));

            // ADVANCED. For advanced usage, generic types can also be imported into
            // the formula evaluator. This is done by adding types of some generic types
            // such as Math, DateTime, Convert, and String. For example, if you add the
            // Convert type, you can then use Convert.ToDecimal("string"). The second
            // parameter to the AddType is the namespace that will be used in the formula.
            // These functions expect a certain type. For example, Math functions expect
            // a Double for the most part. If you pass a string, they will throw an exception.
            // As such, we have written separate functions in FormulaUtils that are more
            // loosely-typed than the standard libraries available here. 
            // Examples:
            Evaluator.Imports.AddType(typeof(Math), "Math");
            Evaluator.Imports.AddType(typeof(DateTime), "DateTime");
            Evaluator.Imports.AddType(typeof(Convert), "Convert");
            Evaluator.Imports.AddType(typeof(String), "String");

            // We want a loosely-typed evaluation language - so do not
            // type-check any variables.
            Evaluator.Options.Checked = false;

            // Our policy is to always treat real numbers as Decimal instead of
            // Double or Single to make it consistent across the entire
            // evaluator.
            Evaluator.Options.RealLiteralDataType = RealLiteralDataType.Decimal;

            // The variable event handler handles the variables based on the DataSource.
            _evaluator.Variables.ResolveVariableType += variables_ResolveVariableType;
            _evaluator.Variables.ResolveVariableValue += variables_ResolveVariableValue;
        }


        /// <summary>
        /// Evaluate the expression passed in as the string
        /// </summary>
        /// <param name="expression">The input whose absolute value is to be found.</param>
        /// <returns>The result of the evaluation. Can we be any data type including string, datetime, decimal, etc.</returns>
        public override object Evaluate(string expression)
        {
            if (expression == null) return null;
            if (expression == "") return "";

            // Strip of the = in the front of the forumula - the Expression evaluator
            // does not need it. Also, make sure to trim the result to remove any
            // spaces in the front and the back.
            expression = expression.TrimStart(new char[] { '=', ' ' }).Trim();

            // Add all realted controls of this control.  This includes the calling control, its children and parents.
            AddRelatedControlVariables();

            // If there are any exceptions when parsing or evaluating, they are
            // thrown so that the end user can see the error. As such, there is no
            // Try-Catch block here.
            try
            {
                IDynamicExpression eDynamic = _evaluator.CompileDynamic(expression);
                return eDynamic.Evaluate();
            }
            catch (Exception ex)
            {
                return "ERROR: " + ex.Message;
            }
        }


        #region "Private functions"
        /// <summary>
        /// Adds related record and table controls.
        /// This has to navigate up to the page level and add any table or record controls.
        /// And we have to navigate within to add any record/table controls.
        /// And we have to go sideways to also add any controls.
        /// Finally we have to add the page control.
        /// This allows the expression to use any record or table control on the page
        /// as long as it is accessible without being in a repeater.
        /// </summary>
        private void AddRelatedControlVariables()
        {
            if ((CallingControl == null)) return;

            try
            {
                // STEP 1: Our strategy is to first add the current control and
                // all of its parents. This way, we maintain the full context of where
                // we are. For example, if you are in a row within a table, within another row
                // that is within another table, then by going up the hierarchy looking for parents
                // will preserve all of the context.
                // Later in Step 2 we will go through the other branches.
                System.Web.UI.Control ctl = CallingControl;
                while (!((ctl == null)))
                {
                    if (ctl is BaseApplicationRecordControl || ctl is BaseApplicationTableControl)
                    {
                        AddControlAndChildren(ctl);
                    }
                    // Navigate up.
                    ctl = ctl.Parent;
                }

                // STEP 2: Go through the other branches on the page and add all other table and 
                // record controls on the page.
                AddControlAndChildren(CallingControl.Page);

                // STEP 3: Add more variable for ASCX control.
                AddVariableNameWithoutUnderscore();

                // STEP 4: Finally add the Page itself.
                Evaluator.Variables.Add("Page", CallingControl.Page);
            }
            catch (Exception)
            {
                // Ignore and continue in case of a problem.
            }
        }

        /// <summary>
        /// Add this control and all child controls of the given control.
        /// We only add the Record and Table Controls. No other controls need
        /// to be added.
        /// This function is smart enough not to add or descend down a control
        /// that was previously added by checking whether the Id is already contained
        /// in the Evaluator variables. This avoids unnecessary traversal.
        /// This function is called recursively to add any child controls.
        /// </summary>
        private void AddControlAndChildren(System.Web.UI.Control ctl)
        {
            // We quit immediately if a control is already in the list of variables,
            // because we have convered that branch already.
            try
            {
                if (ctl == null) return;

                if (!(ctl.ID == null) && Evaluator.Variables.ContainsKey(ctl.ID)) return;

                // If this is a record or table control, add it.
                if (ctl is BaseApplicationRecordControl || ctl is BaseApplicationTableControl)
                {
                    if (!(ctl.ID == null))
                    {
                        Evaluator.Variables.Add(ctl.ID, ctl);
                    }
                }

                foreach (System.Web.UI.Control child in ctl.Controls)
                {
                    // We do not want to go into a repeater because there will be multiple rows.
                    // So we will call AddChildControls only for those controls that are NOT repeaters.
                    if (!(child is System.Web.UI.WebControls.Repeater))
                    {
                        AddControlAndChildren(child);
                    }
                }
            }
            catch (Exception)
            {
                // Ignore - we do not want to give an exception if we cannot add all variables.
            }
        }


        /// <summary>
        /// If the current is not ASPX page but ASCX controls, the controls in this ASCX control has id starting with underscore.
        /// To avoid confusion in formula, we also define variable name without underscore.
        /// </summary>
        /// <remarks></remarks>
        private void AddVariableNameWithoutUnderscore()
        {
            System.Collections.Generic.Dictionary<string, object> vars = new System.Collections.Generic.Dictionary<string, object>();
	        System.Collections.Generic.IEnumerator<System.Collections.Generic.KeyValuePair<string, object>> enumerator = this.Evaluator.Variables.GetEnumerator();
	        while (enumerator.MoveNext()) {
		        if (enumerator.Current.Key.StartsWith("_")) {
			        string varNameWitoutUnderscore = enumerator.Current.Key.Substring(1);
			        if (!this.Evaluator.Variables.ContainsKey(varNameWitoutUnderscore)) 
				        vars.Add(varNameWitoutUnderscore, enumerator.Current.Value);			        
		        }
	        }

            System.Collections.Generic.Dictionary<string, object>.Enumerator enumerator2 = vars.GetEnumerator();
	        while (enumerator2.MoveNext()) {
		        this.Evaluator.Variables.Add(enumerator2.Current.Key, enumerator2.Current.Value);
	        }
        }
        #endregion

    }
}