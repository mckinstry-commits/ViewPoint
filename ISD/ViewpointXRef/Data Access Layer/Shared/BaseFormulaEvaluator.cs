using Microsoft.VisualBasic;
using System.IO;
using BaseClasses.Data;
using Ciloci.Flee;
using System;
using BaseClasses.Utils;

namespace ViewpointXRef.Data
{

    /// <summary>
    /// The BaseFormulaEvaluator class evaluates a formula passed to the Evaluate function.
    /// </summary>
    /// <remarks></remarks>
    public class BaseFormulaEvaluator
    {
        /// <summary>
        /// Evaluator class that actually evaluates the formula.
        /// This is available as a public property, so additional options
        /// can be added to the evaluator from the calling functions.
        /// </summary>
        protected ExpressionContext _evaluator;
        public ExpressionContext Evaluator
        {
            get { return _evaluator; }
        }

        /// <summary>
        /// The Variables collection allows the passing of the variables to the Evaluator
        /// </summary>
        public Ciloci.Flee.VariableCollection Variables
        {
            get { return Evaluator.Variables; }
        }

        /// <summary>
        /// DataSource object from which each of the variables are
        /// determined. This allows direct referencing of the
        /// fields in the DataSource. For example, if the DataSource
        /// is an Order_Details record, then the formula can use something like:
        /// = UnitPrice * Quantity * (1 - Discount)
        /// to calculate the Extended Price.
        /// </summary>
        private BaseRecord _dataSource = null;
        public BaseRecord DataSource
        {
            get { return _dataSource; }
            set { _dataSource = value; }
        }

        /// <summary>
        /// Create a new evaluator and prepare for evaluation.
        /// </summary>
        public BaseFormulaEvaluator()
        {

            _evaluator = new ExpressionContext();

            // The order of adding types is important. First we add our own
            // formula functions, followed by the generic types.

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
        public virtual object Evaluate(string expression)
        {
            if (expression == null) return null;

            if (expression == "") return "";

            // Strip of the = in the front of the forumula - the Expression evaluator
            // does not need it. Also, make sure to trim the result to remove any
            // spaces in the front and the back.
            expression = expression.TrimStart(new char[] { '=', ' ' }).Trim();

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

        /// <summary>
        /// Return the type of the given variable if it exists in the data source.
        /// If the Return Type is Nothing, the evaluator assumes this is an invalid
        /// variable and tries other methods to get its value.
        /// </summary>
        /// <param name="sender">The sender that sent this event.</param>
        /// <param name="e">The event argument. Set e.VariableType.</param>
        protected void variables_ResolveVariableType(object sender, ResolveVariableTypeEventArgs e)
        {
            BaseColumn col = null;

            // Returning Nothing indicates that we do not recognize this variable.
            e.VariableType = null;

            // If no DataSource was set, we do not have variables that we can use
            // directly.
            if ((DataSource == null)) return;

            try
            {
                // Find a column in the datasource using a variable name.
                col = DataSource.TableAccess.TableDefinition.ColumnList.GetByCodeName(e.VariableName);
                if (col == null)
                {
                    // if the variable name ended with "DefaultValue", remmove it and then try to get the column name again.
                    if (e.VariableName.ToLower().EndsWith("defaultvalue"))
                        col = DataSource.TableAccess.TableDefinition.ColumnList.GetByCodeName(e.VariableName.Substring(0, e.VariableName.Length - 12));

                }
                if (col == null)
                    return;

                switch (col.ColumnType)
                {
                    case BaseColumn.ColumnTypes.Number:
                    case BaseColumn.ColumnTypes.Percentage:
                     case  BaseColumn.ColumnTypes.Star:
                        // By default, all our internal data types use Decimal.
                        // This may result in problems when using the Math library
                        // but it reduces the problem by allowing us to loosely-type
                        // all data source properties.
                        e.VariableType = typeof(decimal);

                        break;
                    case BaseColumn.ColumnTypes.Currency:
                        // Convert currency into decimal to allow easier use in formulas
                        e.VariableType = typeof(decimal);

                        break;
                    case BaseColumn.ColumnTypes.Boolean:
                        // Boolean data types are maintained as Boolean and not
                        // converted to Integer as the Binary data type is.
                        e.VariableType = typeof(bool);

                        break;
                    case BaseColumn.ColumnTypes.Credit_Card_Date:
                    case BaseColumn.ColumnTypes.Date:
                        // Use DateTme even for Credit Card Date.
                        e.VariableType = typeof(DateTime);

                        break;
                    case BaseColumn.ColumnTypes.Country:
                    case BaseColumn.ColumnTypes.Credit_Card_Number:
                    case BaseColumn.ColumnTypes.Email:
                    case BaseColumn.ColumnTypes.Password:
                    case BaseColumn.ColumnTypes.String:
                    case BaseColumn.ColumnTypes.Unique_Identifier:
                    case BaseColumn.ColumnTypes.USA_Phone_Number:
                    case BaseColumn.ColumnTypes.USA_State:
                    case BaseColumn.ColumnTypes.USA_Zip_Code:
                    case BaseColumn.ColumnTypes.Very_Large_String:
                    case BaseColumn.ColumnTypes.Web_Url:
                        // For the purpose of formula's, all of the above field types
                        // are treated as strings.
                        e.VariableType = typeof(string);

                        break;
                    case BaseColumn.ColumnTypes.Binary:
                    case BaseColumn.ColumnTypes.File:
                    case BaseColumn.ColumnTypes.Image:
                        // For the purpose of formula's we ignore BLOB fields since they
                        // cannot be used in any calculations or string functions.
                        e.VariableType = null;

                        break;
                    default:
                        // Unknown data type.
                        e.VariableType = null;
                        break;

                }
            }
            catch (Exception)
            {
                // Ignore the error in case we cannot find the variable or its type - simply say that
                // the Variable Type is Nothing - implying that we do not recognize this variable.
            }
        }


        /// <summary>
        /// Return the value of the given variable if it exists in the data source
        /// </summary>
        /// <param name="sender">The input whose absolute value is to be found.</param>
        /// <param name="e">The input whose absolute value is to be found.</param>
        protected void variables_ResolveVariableValue(object sender, ResolveVariableValueEventArgs e)
        {
            BaseColumn col = default(BaseColumn);

            // Default value is Nothing
            e.VariableValue = null;

            // If no DataSource was set, we do not have variables that we can use
            // directly. We should not get here since the request for Type should have
            // caught this.
            if (DataSource == null) return;

            try
            {
                // Find a column in the datasource using a variable name.
                col = DataSource.TableAccess.TableDefinition.ColumnList.GetByCodeName(e.VariableName);
                if (col == null)
                {
                    // if the variable name ended with "DefaultValue", remmove it and then try to get the column name again.
                    if (e.VariableName.ToLower().EndsWith("defaultvalue"))
                        col = DataSource.TableAccess.TableDefinition.ColumnList.GetByCodeName(e.VariableName.Substring(0, e.VariableName.Length - 12));

                    if (col != null)
                    {
                        switch (col.ColumnType)
                        {
                            case BaseColumn.ColumnTypes.Number:
                            case BaseColumn.ColumnTypes.Percentage:
                            case  BaseColumn.ColumnTypes.Star:
                                // The Number and Percentage values are saved as Single. So we first
                                // retrieve the Single value and then convert to Decimal. Our policy is
                                // always to return Decimal (never to return Single or Double) to be constent 
                                // and avoid type conversion in the evaluator.
                                e.VariableValue = BaseFormulaUtils.ParseDecimal(col.DefaultValue);

                                break;
                            case BaseColumn.ColumnTypes.Currency:
                                e.VariableValue = BaseFormulaUtils.ParseDecimal(col.DefaultValue);

                                break;
                            case BaseColumn.ColumnTypes.Boolean:
                                e.VariableValue = col.DefaultValue;

                                break;
                            case BaseColumn.ColumnTypes.Credit_Card_Date:
                            case BaseColumn.ColumnTypes.Date:
                                e.VariableValue = BaseFormulaUtils.ParseDate(col.DefaultValue);

                                break;
                            case BaseColumn.ColumnTypes.Country:
                            case BaseColumn.ColumnTypes.Credit_Card_Number:
                            case BaseColumn.ColumnTypes.Email:
                            case BaseColumn.ColumnTypes.Password:
                            case BaseColumn.ColumnTypes.String:
                            case BaseColumn.ColumnTypes.Unique_Identifier:
                            case BaseColumn.ColumnTypes.USA_Phone_Number:
                            case BaseColumn.ColumnTypes.USA_State:
                            case BaseColumn.ColumnTypes.USA_Zip_Code:
                            case BaseColumn.ColumnTypes.Very_Large_String:
                            case BaseColumn.ColumnTypes.Web_Url:
                                e.VariableValue = col.DefaultValue;

                                break;
                            case BaseColumn.ColumnTypes.File:
                            case BaseColumn.ColumnTypes.Image:
                                // Can't do anything here.
                                e.VariableValue = null;

                                break;
                            default:
                                e.VariableValue = null;
                                break;
                        }
                    }
                }
                else
                {

                    switch (col.ColumnType)
                    {
                        case BaseColumn.ColumnTypes.Number:
                        case BaseColumn.ColumnTypes.Percentage:
                        case  BaseColumn.ColumnTypes.Star:
                            // The Number and Percentage values are saved as Single. So we first
                            // retrieve the Single value and then convert to Decimal. Our policy is
                            // always to return Decimal (never to return Single or Double) to be constent 
                            // and avoid type conversion in the evaluator.
                            e.VariableValue = Decimal.Parse(this.DataSource.GetValue(col).ToDouble().ToString());

                            break;
                        case BaseColumn.ColumnTypes.Currency:
                            e.VariableValue = this.DataSource.GetValue(col).ToDecimal();

                            break;
                        case BaseColumn.ColumnTypes.Boolean:
                            e.VariableValue = this.DataSource.GetValue(col).ToBoolean();

                            break;
                        case BaseColumn.ColumnTypes.Credit_Card_Date:
                        case BaseColumn.ColumnTypes.Date:
                            e.VariableValue = this.DataSource.GetValue(col).ToDateTime();

                            break;
                        case BaseColumn.ColumnTypes.Country:
                        case BaseColumn.ColumnTypes.Credit_Card_Number:
                        case BaseColumn.ColumnTypes.Email:
                        case BaseColumn.ColumnTypes.Password:
                        case BaseColumn.ColumnTypes.String:
                        case BaseColumn.ColumnTypes.Unique_Identifier:
                        case BaseColumn.ColumnTypes.USA_Phone_Number:
                        case BaseColumn.ColumnTypes.USA_State:
                        case BaseColumn.ColumnTypes.USA_Zip_Code:
                        case BaseColumn.ColumnTypes.Very_Large_String:
                        case BaseColumn.ColumnTypes.Web_Url:
                            e.VariableValue = this.DataSource.GetValue(col).ToString();

                            break;
                        case BaseColumn.ColumnTypes.File:
                        case BaseColumn.ColumnTypes.Image:
                            // Can't do anything here.
                            e.VariableValue = null;

                            break;
                        default:
                            e.VariableValue = null;
                            break;
                    }

                }

            }
            catch (Exception)
            {
                // Ignore the error in case we cannot find the variable or its type - simply say that
                // the Variable Type is Nothing - implying that we do not recognize this variable.
            }
        }


        /*This method returns true or false value stating whether to apply GlobalWhereClause to a particular page or not.
        Use this method to exclude pages from applying Global Where Clauses sepcified in Batch Meister Wizard.*/
        public static bool ShouldApplyGlobalWhereClause(string globalWhereClauseFormula)
        {
            if (System.Web.HttpContext.Current == null)
                return true;

	        //Comment out the following code if you want to apply GlobalWhereClause to SignIn and SignOut pages
	        if (!(BaseClasses.Configuration.ApplicationSettings.Current.AuthenticationType == BaseClasses.Configuration.SecurityConstants.None)) {
		        if (!BaseClasses.Configuration.ApplicationSettings.Current.SecurityDisabled) {

			        if (globalWhereClauseFormula.ToLower().Contains("userid()") | globalWhereClauseFormula.ToLower().Contains("username()") | globalWhereClauseFormula.ToLower().Contains("roles()")) {
				        if (System.Web.HttpContext.Current.Request.Url.AbsolutePath.ToLower().Contains(BaseClasses.Configuration.ApplicationSettings.Current.SignInPageUrl.ToString().ToLower())) {
					        return false;
				        }
				        if (System.Web.HttpContext.Current.Request.Url.AbsolutePath.ToLower().Contains(BaseClasses.Configuration.ApplicationSettings.Current.SignedOutPageUrl.ToString().ToLower())) {
					        return false;
				        }
                        if (System.Web.HttpContext.Current.Request.Url.AbsolutePath.ToLower().Contains(BaseClasses.Configuration.ApplicationSettings.Current.ForgotUserPageUrl.ToString().ToLower()))
                        {
                            return false;
                        }
                        if (System.Web.HttpContext.Current.Request.Url.AbsolutePath.ToLower().Contains(BaseClasses.Configuration.ApplicationSettings.Current.SendUserInfoEmailUrl.ToString().ToLower()))
                        {
                            return false;
                        }
                   if (System.Web.HttpContext.Current.Request.Url.AbsolutePath.ToLower().Contains(BaseClasses.Configuration.ApplicationSettings.Current.MobileSignInPageUrl.ToString().ToLower())) {
					        return false;
				        }
				        if (System.Web.HttpContext.Current.Request.Url.AbsolutePath.ToLower().Contains(BaseClasses.Configuration.ApplicationSettings.Current.MobileSignedOutPageUrl.ToString().ToLower())) {
					        return false;
				        }
                        if (System.Web.HttpContext.Current.Request.Url.AbsolutePath.ToLower().Contains(BaseClasses.Configuration.ApplicationSettings.Current.MobileForgotUserPageUrl.ToString().ToLower()))
                        {
                            return false;
                        }
			        }
		        }
	        }
	        return true;
        }


    }
}