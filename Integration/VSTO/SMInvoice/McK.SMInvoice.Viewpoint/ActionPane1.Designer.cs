namespace McK.SMInvoice.Viewpoint
{
    [System.ComponentModel.ToolboxItemAttribute(false)]
    partial class ActionPane1
    {
        /// <summary> 
        /// Required designer variable.
        /// </summary>
        private System.ComponentModel.IContainer components = null;

        /// <summary> 
        /// Clean up any resources being used.
        /// </summary>
        protected override void Dispose(bool disposing)
        {
            if (disposing && (components != null))
            {
                components.Dispose();
            }
            base.Dispose(disposing);
        }

        #region Component Designer generated code

        /// <summary> 
        /// Required method for Designer support - do not modify 
        /// the contents of this method with the code editor.
        /// </summary>
        private void InitializeComponent()
        {
            this.components = new System.ComponentModel.Container();
            System.ComponentModel.ComponentResourceManager resources = new System.ComponentModel.ComponentResourceManager(typeof(ActionPane1));
            this.lblCompany = new System.Windows.Forms.Label();
            this.btnGetInvoices = new System.Windows.Forms.Button();
            this.errorProvider1 = new System.Windows.Forms.ErrorProvider(this.components);
            this.cboCompany = new System.Windows.Forms.ComboBox();
            this.picLogo = new System.Windows.Forms.PictureBox();
            this.lblVersion = new System.Windows.Forms.Label();
            this.label2 = new System.Windows.Forms.Label();
            this.txtInvoiceEnd = new System.Windows.Forms.TextBox();
            this.txtInvoiceStart = new System.Windows.Forms.TextBox();
            this.label7 = new System.Windows.Forms.Label();
            this.label6 = new System.Windows.Forms.Label();
            this.grpStatus = new System.Windows.Forms.GroupBox();
            this.rdoVoided = new System.Windows.Forms.RadioButton();
            this.rdoPending = new System.Windows.Forms.RadioButton();
            this.rdoInvoiced = new System.Windows.Forms.RadioButton();
            this.grpDelivery = new System.Windows.Forms.GroupBox();
            this.rdoNotDelivered = new System.Windows.Forms.RadioButton();
            this.rdoDelivered = new System.Windows.Forms.RadioButton();
            this.rdoDeliveryAll = new System.Windows.Forms.RadioButton();
            this.txtBillToCustomer = new System.Windows.Forms.TextBox();
            this.label9 = new System.Windows.Forms.Label();
            this.btnInputList = new System.Windows.Forms.Button();
            this.grpInvoiceRange = new System.Windows.Forms.GroupBox();
            this.btnReset = new System.Windows.Forms.Button();
            this.btnPreviewOrCopyOffline = new System.Windows.Forms.Button();
            this.btnGetQuotes = new System.Windows.Forms.Button();
            this.btnDeliverInvoices = new System.Windows.Forms.Button();
            this.lblHidden = new System.Windows.Forms.Label();
            this.label5 = new System.Windows.Forms.Label();
            this.cboDivision = new System.Windows.Forms.ComboBox();
            this.cboServiceCenter = new System.Windows.Forms.ComboBox();
            this.label8 = new System.Windows.Forms.Label();
            this.cboTargetEnvironment = new System.Windows.Forms.ComboBox();
            this.grpTandM = new System.Windows.Forms.GroupBox();
            this.rdoTandMHideLaborRate = new System.Windows.Forms.RadioButton();
            this.rdoTandMShowLaborRate = new System.Windows.Forms.RadioButton();
            this.tmrAlertCell = new System.Windows.Forms.Timer(this.components);
            ((System.ComponentModel.ISupportInitialize)(this.errorProvider1)).BeginInit();
            ((System.ComponentModel.ISupportInitialize)(this.picLogo)).BeginInit();
            this.grpStatus.SuspendLayout();
            this.grpDelivery.SuspendLayout();
            this.grpInvoiceRange.SuspendLayout();
            this.grpTandM.SuspendLayout();
            this.SuspendLayout();
            // 
            // lblCompany
            // 
            this.lblCompany.AutoSize = true;
            this.lblCompany.Font = new System.Drawing.Font("Microsoft Sans Serif", 9.5F);
            this.lblCompany.Location = new System.Drawing.Point(-1, 98);
            this.lblCompany.Name = "lblCompany";
            this.lblCompany.Size = new System.Drawing.Size(80, 20);
            this.lblCompany.TabIndex = 6;
            this.lblCompany.Text = "Company:";
            // 
            // btnGetInvoices
            // 
            this.btnGetInvoices.Font = new System.Drawing.Font("Microsoft Sans Serif", 9F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.btnGetInvoices.Location = new System.Drawing.Point(6, 701);
            this.btnGetInvoices.Name = "btnGetInvoices";
            this.btnGetInvoices.Size = new System.Drawing.Size(182, 50);
            this.btnGetInvoices.TabIndex = 10;
            this.btnGetInvoices.Text = "Get Invoices";
            this.btnGetInvoices.UseVisualStyleBackColor = true;
            this.btnGetInvoices.Click += new System.EventHandler(this.btnGetInvoices_Click);
            this.btnGetInvoices.KeyUp += new System.Windows.Forms.KeyEventHandler(this.ctrl_KeyUp);
            // 
            // errorProvider1
            // 
            this.errorProvider1.ContainerControl = this;
            // 
            // cboCompany
            // 
            this.cboCompany.BackColor = System.Drawing.SystemColors.Info;
            this.cboCompany.DrawMode = System.Windows.Forms.DrawMode.OwnerDrawFixed;
            this.cboCompany.DropDownStyle = System.Windows.Forms.ComboBoxStyle.DropDownList;
            this.cboCompany.DropDownWidth = 200;
            this.cboCompany.Font = new System.Drawing.Font("Microsoft Sans Serif", 9F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.cboCompany.ForeColor = System.Drawing.SystemColors.WindowText;
            this.cboCompany.FormattingEnabled = true;
            this.cboCompany.Location = new System.Drawing.Point(1, 117);
            this.cboCompany.Name = "cboCompany";
            this.cboCompany.Size = new System.Drawing.Size(187, 25);
            this.cboCompany.TabIndex = 0;
            this.cboCompany.DrawItem += new System.Windows.Forms.DrawItemEventHandler(this.cboCompany_DrawItem);
            this.cboCompany.KeyUp += new System.Windows.Forms.KeyEventHandler(this.cboCompany_KeyUp);
            this.cboCompany.Leave += new System.EventHandler(this.cboCompany_Leave);
            // 
            // picLogo
            // 
            this.picLogo.Image = ((System.Drawing.Image)(resources.GetObject("picLogo.Image")));
            this.picLogo.Location = new System.Drawing.Point(0, 0);
            this.picLogo.Name = "picLogo";
            this.picLogo.Size = new System.Drawing.Size(95, 48);
            this.picLogo.SizeMode = System.Windows.Forms.PictureBoxSizeMode.StretchImage;
            this.picLogo.TabIndex = 4;
            this.picLogo.TabStop = false;
            // 
            // lblVersion
            // 
            this.lblVersion.Font = new System.Drawing.Font("Microsoft Sans Serif", 9F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.lblVersion.Location = new System.Drawing.Point(112, 24);
            this.lblVersion.Margin = new System.Windows.Forms.Padding(2, 0, 2, 0);
            this.lblVersion.Name = "lblVersion";
            this.lblVersion.Size = new System.Drawing.Size(74, 20);
            this.lblVersion.TabIndex = 44;
            this.lblVersion.Text = "v1.0.0.0";
            this.lblVersion.UseCompatibleTextRendering = true;
            this.lblVersion.UseMnemonic = false;
            // 
            // label2
            // 
            this.label2.BackColor = System.Drawing.Color.Transparent;
            this.label2.Font = new System.Drawing.Font("Microsoft Sans Serif", 9.75F, System.Drawing.FontStyle.Bold, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.label2.Location = new System.Drawing.Point(99, 6);
            this.label2.Margin = new System.Windows.Forms.Padding(2, 0, 2, 0);
            this.label2.Name = "label2";
            this.label2.Size = new System.Drawing.Size(89, 18);
            this.label2.TabIndex = 42;
            this.label2.Text = "SM Invoice";
            this.label2.UseMnemonic = false;
            // 
            // txtInvoiceEnd
            // 
            this.txtInvoiceEnd.BackColor = System.Drawing.SystemColors.Info;
            this.txtInvoiceEnd.Font = new System.Drawing.Font("Microsoft Sans Serif", 9.75F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.txtInvoiceEnd.Location = new System.Drawing.Point(10, 67);
            this.txtInvoiceEnd.Name = "txtInvoiceEnd";
            this.txtInvoiceEnd.Size = new System.Drawing.Size(95, 26);
            this.txtInvoiceEnd.TabIndex = 1;
            this.txtInvoiceEnd.TextAlign = System.Windows.Forms.HorizontalAlignment.Center;
            this.txtInvoiceEnd.TextChanged += new System.EventHandler(this.txtInvoiceEnd_TextChanged);
            this.txtInvoiceEnd.KeyUp += new System.Windows.Forms.KeyEventHandler(this.ctrl_KeyUp);
            // 
            // txtInvoiceStart
            // 
            this.txtInvoiceStart.BackColor = System.Drawing.SystemColors.Info;
            this.txtInvoiceStart.Font = new System.Drawing.Font("Microsoft Sans Serif", 9.75F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.txtInvoiceStart.Location = new System.Drawing.Point(9, 19);
            this.txtInvoiceStart.MaxLength = 4000;
            this.txtInvoiceStart.Name = "txtInvoiceStart";
            this.txtInvoiceStart.Size = new System.Drawing.Size(97, 26);
            this.txtInvoiceStart.TabIndex = 0;
            this.txtInvoiceStart.TextAlign = System.Windows.Forms.HorizontalAlignment.Center;
            this.txtInvoiceStart.TextChanged += new System.EventHandler(this.txtInvoiceStart_TextChanged);
            this.txtInvoiceStart.KeyUp += new System.Windows.Forms.KeyEventHandler(this.ctrl_KeyUp);
            // 
            // label7
            // 
            this.label7.AutoSize = true;
            this.label7.Font = new System.Drawing.Font("Microsoft Sans Serif", 9.75F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.label7.Location = new System.Drawing.Point(6, -2);
            this.label7.Name = "label7";
            this.label7.Size = new System.Drawing.Size(107, 20);
            this.label7.TabIndex = 6;
            this.label7.Text = "Start Invoice:";
            // 
            // label6
            // 
            this.label6.AutoSize = true;
            this.label6.Font = new System.Drawing.Font("Microsoft Sans Serif", 9.75F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.label6.Location = new System.Drawing.Point(7, 48);
            this.label6.Name = "label6";
            this.label6.Size = new System.Drawing.Size(100, 20);
            this.label6.TabIndex = 56;
            this.label6.Text = "End Invoice:";
            // 
            // grpStatus
            // 
            this.grpStatus.Controls.Add(this.rdoVoided);
            this.grpStatus.Controls.Add(this.rdoPending);
            this.grpStatus.Controls.Add(this.rdoInvoiced);
            this.grpStatus.Cursor = System.Windows.Forms.Cursors.Hand;
            this.grpStatus.Location = new System.Drawing.Point(2, 149);
            this.grpStatus.Name = "grpStatus";
            this.grpStatus.Size = new System.Drawing.Size(199, 48);
            this.grpStatus.TabIndex = 1;
            this.grpStatus.TabStop = false;
            this.grpStatus.Text = "Invoice Status";
            // 
            // rdoVoided
            // 
            this.rdoVoided.AutoSize = true;
            this.rdoVoided.Font = new System.Drawing.Font("Microsoft Sans Serif", 7.8F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.rdoVoided.Location = new System.Drawing.Point(134, 21);
            this.rdoVoided.Name = "rdoVoided";
            this.rdoVoided.Size = new System.Drawing.Size(73, 21);
            this.rdoVoided.TabIndex = 2;
            this.rdoVoided.TabStop = true;
            this.rdoVoided.Text = "Voided";
            this.rdoVoided.UseVisualStyleBackColor = true;
            this.rdoVoided.CheckedChanged += new System.EventHandler(this.radioButton_CheckedChanged);
            this.rdoVoided.KeyUp += new System.Windows.Forms.KeyEventHandler(this.ctrl_KeyUp);
            // 
            // rdoPending
            // 
            this.rdoPending.AutoSize = true;
            this.rdoPending.Font = new System.Drawing.Font("Microsoft Sans Serif", 7.8F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.rdoPending.Location = new System.Drawing.Point(71, 21);
            this.rdoPending.Name = "rdoPending";
            this.rdoPending.Size = new System.Drawing.Size(81, 21);
            this.rdoPending.TabIndex = 1;
            this.rdoPending.TabStop = true;
            this.rdoPending.Text = "Pending";
            this.rdoPending.UseVisualStyleBackColor = true;
            this.rdoPending.CheckedChanged += new System.EventHandler(this.radioButton_CheckedChanged);
            this.rdoPending.KeyUp += new System.Windows.Forms.KeyEventHandler(this.ctrl_KeyUp);
            // 
            // rdoInvoiced
            // 
            this.rdoInvoiced.AutoSize = true;
            this.rdoInvoiced.Font = new System.Drawing.Font("Microsoft Sans Serif", 7.8F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.rdoInvoiced.Location = new System.Drawing.Point(3, 21);
            this.rdoInvoiced.Name = "rdoInvoiced";
            this.rdoInvoiced.Size = new System.Drawing.Size(81, 21);
            this.rdoInvoiced.TabIndex = 0;
            this.rdoInvoiced.TabStop = true;
            this.rdoInvoiced.Text = "Invoiced";
            this.rdoInvoiced.UseVisualStyleBackColor = true;
            this.rdoInvoiced.CheckedChanged += new System.EventHandler(this.radioButton_CheckedChanged);
            this.rdoInvoiced.KeyUp += new System.Windows.Forms.KeyEventHandler(this.ctrl_KeyUp);
            // 
            // grpDelivery
            // 
            this.grpDelivery.Controls.Add(this.rdoNotDelivered);
            this.grpDelivery.Controls.Add(this.rdoDelivered);
            this.grpDelivery.Controls.Add(this.rdoDeliveryAll);
            this.grpDelivery.Cursor = System.Windows.Forms.Cursors.Hand;
            this.grpDelivery.Location = new System.Drawing.Point(3, 204);
            this.grpDelivery.Name = "grpDelivery";
            this.grpDelivery.Size = new System.Drawing.Size(132, 95);
            this.grpDelivery.TabIndex = 2;
            this.grpDelivery.TabStop = false;
            this.grpDelivery.Text = "Delivery Status";
            // 
            // rdoNotDelivered
            // 
            this.rdoNotDelivered.AutoSize = true;
            this.rdoNotDelivered.Checked = true;
            this.rdoNotDelivered.Location = new System.Drawing.Point(11, 65);
            this.rdoNotDelivered.Name = "rdoNotDelivered";
            this.rdoNotDelivered.Size = new System.Drawing.Size(132, 24);
            this.rdoNotDelivered.TabIndex = 2;
            this.rdoNotDelivered.TabStop = true;
            this.rdoNotDelivered.Text = "Not Delivered";
            this.rdoNotDelivered.UseVisualStyleBackColor = true;
            this.rdoNotDelivered.CheckedChanged += new System.EventHandler(this.rdoNotDelivered_CheckedChanged);
            this.rdoNotDelivered.KeyUp += new System.Windows.Forms.KeyEventHandler(this.ctrl_KeyUp);
            // 
            // rdoDelivered
            // 
            this.rdoDelivered.AutoSize = true;
            this.rdoDelivered.Location = new System.Drawing.Point(12, 41);
            this.rdoDelivered.Name = "rdoDelivered";
            this.rdoDelivered.Size = new System.Drawing.Size(101, 24);
            this.rdoDelivered.TabIndex = 1;
            this.rdoDelivered.Text = "Delivered";
            this.rdoDelivered.UseVisualStyleBackColor = true;
            this.rdoDelivered.CheckedChanged += new System.EventHandler(this.rdoDelivered_CheckedChanged);
            this.rdoDelivered.KeyUp += new System.Windows.Forms.KeyEventHandler(this.ctrl_KeyUp);
            // 
            // rdoDeliveryAll
            // 
            this.rdoDeliveryAll.AutoSize = true;
            this.rdoDeliveryAll.Location = new System.Drawing.Point(12, 19);
            this.rdoDeliveryAll.Name = "rdoDeliveryAll";
            this.rdoDeliveryAll.Size = new System.Drawing.Size(49, 24);
            this.rdoDeliveryAll.TabIndex = 0;
            this.rdoDeliveryAll.Text = "All";
            this.rdoDeliveryAll.UseVisualStyleBackColor = true;
            this.rdoDeliveryAll.CheckedChanged += new System.EventHandler(this.rdoDeliveryAll_CheckedChanged);
            this.rdoDeliveryAll.KeyUp += new System.Windows.Forms.KeyEventHandler(this.ctrl_KeyUp);
            // 
            // txtBillToCustomer
            // 
            this.txtBillToCustomer.BackColor = System.Drawing.SystemColors.Info;
            this.txtBillToCustomer.Location = new System.Drawing.Point(6, 406);
            this.txtBillToCustomer.MaxLength = 4000;
            this.txtBillToCustomer.Name = "txtBillToCustomer";
            this.txtBillToCustomer.Size = new System.Drawing.Size(187, 26);
            this.txtBillToCustomer.TabIndex = 3;
            this.txtBillToCustomer.TextChanged += new System.EventHandler(this.txtBillToCustomer_TextChanged);
            this.txtBillToCustomer.KeyDown += new System.Windows.Forms.KeyEventHandler(this.txtBillToCustomer_KeyDown);
            this.txtBillToCustomer.KeyUp += new System.Windows.Forms.KeyEventHandler(this.ctrl_KeyUp);
            // 
            // label9
            // 
            this.label9.AutoSize = true;
            this.label9.Font = new System.Drawing.Font("Microsoft Sans Serif", 9.75F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.label9.Location = new System.Drawing.Point(3, 385);
            this.label9.Name = "label9";
            this.label9.Size = new System.Drawing.Size(140, 20);
            this.label9.TabIndex = 61;
            this.label9.Text = "Bill To Customer:";
            // 
            // btnInputList
            // 
            this.btnInputList.Font = new System.Drawing.Font("Microsoft Sans Serif", 9.75F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.btnInputList.Location = new System.Drawing.Point(7, 656);
            this.btnInputList.Name = "btnInputList";
            this.btnInputList.Size = new System.Drawing.Size(180, 29);
            this.btnInputList.TabIndex = 9;
            this.btnInputList.Text = "Open Input List";
            this.btnInputList.UseVisualStyleBackColor = true;
            this.btnInputList.Click += new System.EventHandler(this.btnInputList_Click);
            // 
            // grpInvoiceRange
            // 
            this.grpInvoiceRange.Controls.Add(this.btnReset);
            this.grpInvoiceRange.Controls.Add(this.txtInvoiceEnd);
            this.grpInvoiceRange.Controls.Add(this.label6);
            this.grpInvoiceRange.Controls.Add(this.label7);
            this.grpInvoiceRange.Controls.Add(this.txtInvoiceStart);
            this.grpInvoiceRange.Location = new System.Drawing.Point(-2, 551);
            this.grpInvoiceRange.Name = "grpInvoiceRange";
            this.grpInvoiceRange.Size = new System.Drawing.Size(196, 99);
            this.grpInvoiceRange.TabIndex = 4;
            this.grpInvoiceRange.TabStop = false;
            // 
            // btnReset
            // 
            this.btnReset.Font = new System.Drawing.Font("Microsoft Sans Serif", 9F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.btnReset.Location = new System.Drawing.Point(120, 19);
            this.btnReset.Name = "btnReset";
            this.btnReset.Size = new System.Drawing.Size(69, 70);
            this.btnReset.TabIndex = 2;
            this.btnReset.Text = "Reset";
            this.btnReset.UseVisualStyleBackColor = true;
            this.btnReset.Click += new System.EventHandler(this.btnReset_Click);
            // 
            // btnPreviewOrCopyOffline
            // 
            this.btnPreviewOrCopyOffline.BackColor = System.Drawing.SystemColors.ControlLight;
            this.btnPreviewOrCopyOffline.Enabled = false;
            this.btnPreviewOrCopyOffline.Font = new System.Drawing.Font("Microsoft Sans Serif", 9F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.btnPreviewOrCopyOffline.Location = new System.Drawing.Point(6, 758);
            this.btnPreviewOrCopyOffline.Name = "btnPreviewOrCopyOffline";
            this.btnPreviewOrCopyOffline.Size = new System.Drawing.Size(181, 50);
            this.btnPreviewOrCopyOffline.TabIndex = 11;
            this.btnPreviewOrCopyOffline.Text = "Preview Invoices";
            this.btnPreviewOrCopyOffline.UseVisualStyleBackColor = true;
            this.btnPreviewOrCopyOffline.Click += new System.EventHandler(this.btnPreview_or_CopyOffline_Click);
            this.btnPreviewOrCopyOffline.KeyUp += new System.Windows.Forms.KeyEventHandler(this.btnPreviewOrCopyOffline_KeyUp);
            // 
            // btnGetQuotes
            // 
            this.btnGetQuotes.Font = new System.Drawing.Font("Microsoft Sans Serif", 9F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.btnGetQuotes.Location = new System.Drawing.Point(5, 883);
            this.btnGetQuotes.Name = "btnGetQuotes";
            this.btnGetQuotes.Size = new System.Drawing.Size(182, 31);
            this.btnGetQuotes.TabIndex = 13;
            this.btnGetQuotes.Text = "Get Quotes";
            this.btnGetQuotes.UseVisualStyleBackColor = true;
            this.btnGetQuotes.Click += new System.EventHandler(this.btnGetQuotes_Click);
            // 
            // btnDeliverInvoices
            // 
            this.btnDeliverInvoices.Enabled = false;
            this.btnDeliverInvoices.Font = new System.Drawing.Font("Microsoft Sans Serif", 9F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.btnDeliverInvoices.Location = new System.Drawing.Point(6, 814);
            this.btnDeliverInvoices.Name = "btnDeliverInvoices";
            this.btnDeliverInvoices.Size = new System.Drawing.Size(182, 50);
            this.btnDeliverInvoices.TabIndex = 12;
            this.btnDeliverInvoices.Text = "Deliver Invoices";
            this.btnDeliverInvoices.UseVisualStyleBackColor = true;
            this.btnDeliverInvoices.Click += new System.EventHandler(this.btnDeliverInvoices_Click);
            this.btnDeliverInvoices.KeyUp += new System.Windows.Forms.KeyEventHandler(this.btnDeliverInvoices_KeyUp);
            // 
            // lblHidden
            // 
            this.lblHidden.AutoSize = true;
            this.lblHidden.Enabled = false;
            this.lblHidden.Font = new System.Drawing.Font("Microsoft Sans Serif", 9.75F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.lblHidden.Location = new System.Drawing.Point(210, 493);
            this.lblHidden.Name = "lblHidden";
            this.lblHidden.Size = new System.Drawing.Size(116, 20);
            this.lblHidden.TabIndex = 58;
            this.lblHidden.Text = "Focus capture";
            this.lblHidden.Visible = false;
            // 
            // label5
            // 
            this.label5.AutoSize = true;
            this.label5.Font = new System.Drawing.Font("Microsoft Sans Serif", 9.75F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.label5.Location = new System.Drawing.Point(4, 440);
            this.label5.Name = "label5";
            this.label5.Size = new System.Drawing.Size(69, 20);
            this.label5.TabIndex = 66;
            this.label5.Text = "Division";
            // 
            // cboDivision
            // 
            this.cboDivision.BackColor = System.Drawing.SystemColors.Info;
            this.cboDivision.DrawMode = System.Windows.Forms.DrawMode.OwnerDrawFixed;
            this.cboDivision.DropDownStyle = System.Windows.Forms.ComboBoxStyle.DropDownList;
            this.cboDivision.DropDownWidth = 180;
            this.cboDivision.Font = new System.Drawing.Font("Microsoft Sans Serif", 9F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.cboDivision.ForeColor = System.Drawing.SystemColors.WindowText;
            this.cboDivision.FormattingEnabled = true;
            this.cboDivision.Location = new System.Drawing.Point(6, 459);
            this.cboDivision.Name = "cboDivision";
            this.cboDivision.Size = new System.Drawing.Size(159, 25);
            this.cboDivision.TabIndex = 4;
            this.cboDivision.DrawItem += new System.Windows.Forms.DrawItemEventHandler(this.cboCompany_DrawItem);
            this.cboDivision.SelectedIndexChanged += new System.EventHandler(this.cboDivision_SelectedIndexChanged);
            this.cboDivision.KeyUp += new System.Windows.Forms.KeyEventHandler(this.ctrl_KeyUp);
            // 
            // cboServiceCenter
            // 
            this.cboServiceCenter.BackColor = System.Drawing.SystemColors.Info;
            this.cboServiceCenter.DrawMode = System.Windows.Forms.DrawMode.OwnerDrawFixed;
            this.cboServiceCenter.DropDownStyle = System.Windows.Forms.ComboBoxStyle.DropDownList;
            this.cboServiceCenter.DropDownWidth = 180;
            this.cboServiceCenter.Font = new System.Drawing.Font("Microsoft Sans Serif", 9F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.cboServiceCenter.ForeColor = System.Drawing.SystemColors.WindowText;
            this.cboServiceCenter.FormattingEnabled = true;
            this.cboServiceCenter.Location = new System.Drawing.Point(6, 511);
            this.cboServiceCenter.Name = "cboServiceCenter";
            this.cboServiceCenter.Size = new System.Drawing.Size(159, 25);
            this.cboServiceCenter.TabIndex = 5;
            this.cboServiceCenter.DrawItem += new System.Windows.Forms.DrawItemEventHandler(this.cboCompany_DrawItem);
            this.cboServiceCenter.SelectedIndexChanged += new System.EventHandler(this.cboServiceCenter_SelectedIndexChanged);
            this.cboServiceCenter.KeyUp += new System.Windows.Forms.KeyEventHandler(this.ctrl_KeyUp);
            // 
            // label8
            // 
            this.label8.AutoSize = true;
            this.label8.Font = new System.Drawing.Font("Microsoft Sans Serif", 9.75F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.label8.Location = new System.Drawing.Point(4, 492);
            this.label8.Name = "label8";
            this.label8.Size = new System.Drawing.Size(120, 20);
            this.label8.TabIndex = 69;
            this.label8.Text = "Service Center";
            // 
            // cboTargetEnvironment
            // 
            this.cboTargetEnvironment.BackColor = System.Drawing.Color.Black;
            this.cboTargetEnvironment.DrawMode = System.Windows.Forms.DrawMode.OwnerDrawFixed;
            this.cboTargetEnvironment.DropDownStyle = System.Windows.Forms.ComboBoxStyle.DropDownList;
            this.cboTargetEnvironment.DropDownWidth = 200;
            this.cboTargetEnvironment.Font = new System.Drawing.Font("Microsoft Sans Serif", 14.25F, System.Drawing.FontStyle.Bold);
            this.cboTargetEnvironment.ForeColor = System.Drawing.Color.Yellow;
            this.cboTargetEnvironment.FormattingEnabled = true;
            this.cboTargetEnvironment.ItemHeight = 26;
            this.cboTargetEnvironment.Location = new System.Drawing.Point(30, 61);
            this.cboTargetEnvironment.Name = "cboTargetEnvironment";
            this.cboTargetEnvironment.Size = new System.Drawing.Size(139, 32);
            this.cboTargetEnvironment.TabIndex = 81;
            this.cboTargetEnvironment.DrawItem += new System.Windows.Forms.DrawItemEventHandler(this.cboTargetEnvironment_DrawItem);
            this.cboTargetEnvironment.SelectedIndexChanged += new System.EventHandler(this.cboTargetEnvironment_SelectedIndexChanged);
            // 
            // grpTandM
            // 
            this.grpTandM.Controls.Add(this.rdoTandMHideLaborRate);
            this.grpTandM.Controls.Add(this.rdoTandMShowLaborRate);
            this.grpTandM.Cursor = System.Windows.Forms.Cursors.Hand;
            this.grpTandM.Location = new System.Drawing.Point(3, 305);
            this.grpTandM.Name = "grpTandM";
            this.grpTandM.Size = new System.Drawing.Size(134, 69);
            this.grpTandM.TabIndex = 3;
            this.grpTandM.TabStop = false;
            this.grpTandM.Text = "T&&M Labor";
            // 
            // rdoTandMHideLaborRate
            // 
            this.rdoTandMHideLaborRate.AutoSize = true;
            this.rdoTandMHideLaborRate.Checked = true;
            this.rdoTandMHideLaborRate.Location = new System.Drawing.Point(13, 21);
            this.rdoTandMHideLaborRate.Name = "rdoTandMHideLaborRate";
            this.rdoTandMHideLaborRate.Size = new System.Drawing.Size(105, 24);
            this.rdoTandMHideLaborRate.TabIndex = 1;
            this.rdoTandMHideLaborRate.TabStop = true;
            this.rdoTandMHideLaborRate.Text = "Hide Rate";
            this.rdoTandMHideLaborRate.UseVisualStyleBackColor = true;
            this.rdoTandMHideLaborRate.CheckedChanged += new System.EventHandler(this.rdoSumTandM_CheckedChanged);
            // 
            // rdoTandMShowLaborRate
            // 
            this.rdoTandMShowLaborRate.AutoSize = true;
            this.rdoTandMShowLaborRate.Location = new System.Drawing.Point(13, 43);
            this.rdoTandMShowLaborRate.Name = "rdoTandMShowLaborRate";
            this.rdoTandMShowLaborRate.Size = new System.Drawing.Size(111, 24);
            this.rdoTandMShowLaborRate.TabIndex = 0;
            this.rdoTandMShowLaborRate.Text = "Show Rate";
            this.rdoTandMShowLaborRate.UseVisualStyleBackColor = true;
            this.rdoTandMShowLaborRate.CheckedChanged += new System.EventHandler(this.rdoDetailTandM_CheckedChanged);
            // 
            // tmrAlertCell
            // 
            this.tmrAlertCell.Interval = 300;
            this.tmrAlertCell.Tick += new System.EventHandler(this.tmrAlertCell_Tick);
            // 
            // ActionPane1
            // 
            this.AutoValidate = System.Windows.Forms.AutoValidate.EnableAllowFocusChange;
            this.Controls.Add(this.grpTandM);
            this.Controls.Add(this.cboTargetEnvironment);
            this.Controls.Add(this.cboServiceCenter);
            this.Controls.Add(this.label8);
            this.Controls.Add(this.cboDivision);
            this.Controls.Add(this.label5);
            this.Controls.Add(this.lblHidden);
            this.Controls.Add(this.btnDeliverInvoices);
            this.Controls.Add(this.btnGetQuotes);
            this.Controls.Add(this.btnInputList);
            this.Controls.Add(this.btnPreviewOrCopyOffline);
            this.Controls.Add(this.grpInvoiceRange);
            this.Controls.Add(this.txtBillToCustomer);
            this.Controls.Add(this.label9);
            this.Controls.Add(this.grpDelivery);
            this.Controls.Add(this.grpStatus);
            this.Controls.Add(this.lblVersion);
            this.Controls.Add(this.label2);
            this.Controls.Add(this.cboCompany);
            this.Controls.Add(this.btnGetInvoices);
            this.Controls.Add(this.lblCompany);
            this.Controls.Add(this.picLogo);
            this.Font = new System.Drawing.Font("Microsoft Sans Serif", 9.75F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.ForeColor = System.Drawing.SystemColors.WindowText;
            this.Name = "ActionPane1";
            this.Size = new System.Drawing.Size(183, 925);
            ((System.ComponentModel.ISupportInitialize)(this.errorProvider1)).EndInit();
            ((System.ComponentModel.ISupportInitialize)(this.picLogo)).EndInit();
            this.grpStatus.ResumeLayout(false);
            this.grpStatus.PerformLayout();
            this.grpDelivery.ResumeLayout(false);
            this.grpDelivery.PerformLayout();
            this.grpInvoiceRange.ResumeLayout(false);
            this.grpInvoiceRange.PerformLayout();
            this.grpTandM.ResumeLayout(false);
            this.grpTandM.PerformLayout();
            this.ResumeLayout(false);
            this.PerformLayout();

        }

        #endregion
        private System.Windows.Forms.Label lblCompany;
        internal System.Windows.Forms.Button btnGetInvoices;
        private System.Windows.Forms.ErrorProvider errorProvider1;
        internal System.Windows.Forms.ComboBox cboCompany;
        private System.Windows.Forms.Label lblVersion;
        private System.Windows.Forms.Label label2;
        private System.Windows.Forms.PictureBox picLogo;
        internal System.Windows.Forms.TextBox txtInvoiceEnd;
        internal System.Windows.Forms.TextBox txtInvoiceStart;
        private System.Windows.Forms.Label label7;
        private System.Windows.Forms.Label label6;
        private System.Windows.Forms.GroupBox grpDelivery;
        private System.Windows.Forms.RadioButton rdoNotDelivered;
        private System.Windows.Forms.RadioButton rdoDelivered;
        private System.Windows.Forms.RadioButton rdoDeliveryAll;
        private System.Windows.Forms.GroupBox grpStatus;
        private System.Windows.Forms.RadioButton rdoPending;
        private System.Windows.Forms.RadioButton rdoInvoiced;
        internal System.Windows.Forms.TextBox txtBillToCustomer;
        private System.Windows.Forms.Label label9;
        internal System.Windows.Forms.Button btnInputList;
        private System.Windows.Forms.GroupBox grpInvoiceRange;
        internal System.Windows.Forms.Button btnPreviewOrCopyOffline;
        internal System.Windows.Forms.Button btnGetQuotes;
        internal System.Windows.Forms.Button btnDeliverInvoices;
        private System.Windows.Forms.RadioButton rdoVoided;
        private System.Windows.Forms.Label lblHidden;
        private System.Windows.Forms.Label label5;
        private System.Windows.Forms.ComboBox cboDivision;
        private System.Windows.Forms.ComboBox cboServiceCenter;
        private System.Windows.Forms.Label label8;
        internal System.Windows.Forms.Button btnReset;
        internal System.Windows.Forms.ComboBox cboTargetEnvironment;
        private System.Windows.Forms.GroupBox grpTandM;
        private System.Windows.Forms.RadioButton rdoTandMHideLaborRate;
        private System.Windows.Forms.RadioButton rdoTandMShowLaborRate;
        private System.Windows.Forms.Timer tmrAlertCell;
    }
}
