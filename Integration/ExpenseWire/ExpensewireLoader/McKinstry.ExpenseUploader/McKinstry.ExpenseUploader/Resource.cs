using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace McKinstry.ExpenseUploader.Resource
{
    public class XMLPATH
    {
        public const string COMPANY = "";
        public const string DEPARTMENT = "Department/DivisionGLPrefix";
        public const string EMPLOYEENUMBER = "User/ExternalID";
        public const string USEREMAIL = "User/UserID";
        public const string EXPENSETITLE = "ExpneseTitle";
        public const string TOTALREIMBURABLE = "TotalReimbursable";
        public const string CREATEDDATE = "CreatedDate";

        public const string BATCHNUMBER = "//ExpenseWire/DataTransaction/Expense/Search/Batch/BatchNumber";
        public const string EXPENSES = "//ExpenseWire/SendDataTransaction/Expense/Search/Expense";

    }
}
