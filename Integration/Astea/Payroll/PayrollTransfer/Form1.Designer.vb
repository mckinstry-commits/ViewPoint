<Global.Microsoft.VisualBasic.CompilerServices.DesignerGenerated()> _
Partial Class mainForm
    Inherits System.Windows.Forms.Form

    'Form overrides dispose to clean up the component list.
    <System.Diagnostics.DebuggerNonUserCode()> _
    Protected Overrides Sub Dispose(ByVal disposing As Boolean)
        Try
            If disposing AndAlso components IsNot Nothing Then
                components.Dispose()
            End If
        Finally
            MyBase.Dispose(disposing)
        End Try
    End Sub

    'Required by the Windows Form Designer
    Private components As System.ComponentModel.IContainer

    'NOTE: The following procedure is required by the Windows Form Designer
    'It can be modified using the Windows Form Designer.  
    'Do not modify it using the code editor.
    <System.Diagnostics.DebuggerStepThrough()> _
    Private Sub InitializeComponent()
        Me.cb_node = New System.Windows.Forms.ComboBox()
        Me.node_t = New System.Windows.Forms.Label()
        Me.b_ok = New System.Windows.Forms.Button()
        Me.b_cancel = New System.Windows.Forms.Button()
        Me.cbx_testmode = New System.Windows.Forms.CheckBox()
        Me.txt_payseq = New System.Windows.Forms.TextBox()
        Me.payseq_t = New System.Windows.Forms.Label()
        Me.actgr_t = New System.Windows.Forms.Label()
        Me.txt_actgr = New System.Windows.Forms.TextBox()
        Me.txt_file = New System.Windows.Forms.TextBox()
        Me.file_t = New System.Windows.Forms.Label()
        Me.GroupBox1 = New System.Windows.Forms.GroupBox()
        Me.dt_end = New System.Windows.Forms.DateTimePicker()
        Me.enddate_t = New System.Windows.Forms.Label()
        Me.txt_status = New System.Windows.Forms.TextBox()
        Me.GroupBox1.SuspendLayout()
        Me.SuspendLayout()
        '
        'cb_node
        '
        Me.cb_node.FormattingEnabled = True
        Me.cb_node.Location = New System.Drawing.Point(140, 17)
        Me.cb_node.Name = "cb_node"
        Me.cb_node.Size = New System.Drawing.Size(155, 21)
        Me.cb_node.TabIndex = 0
        '
        'node_t
        '
        Me.node_t.AutoSize = True
        Me.node_t.Location = New System.Drawing.Point(48, 20)
        Me.node_t.Name = "node_t"
        Me.node_t.Size = New System.Drawing.Size(85, 13)
        Me.node_t.TabIndex = 1
        Me.node_t.Text = "Employee Node:"
        '
        'b_ok
        '
        Me.b_ok.Location = New System.Drawing.Point(63, 215)
        Me.b_ok.Name = "b_ok"
        Me.b_ok.Size = New System.Drawing.Size(75, 23)
        Me.b_ok.TabIndex = 2
        Me.b_ok.Text = "Transfer"
        Me.b_ok.UseVisualStyleBackColor = True
        '
        'b_cancel
        '
        Me.b_cancel.Location = New System.Drawing.Point(220, 215)
        Me.b_cancel.Name = "b_cancel"
        Me.b_cancel.Size = New System.Drawing.Size(75, 23)
        Me.b_cancel.TabIndex = 3
        Me.b_cancel.Text = "Quit"
        Me.b_cancel.UseVisualStyleBackColor = True
        '
        'cbx_testmode
        '
        Me.cbx_testmode.AutoSize = True
        Me.cbx_testmode.Location = New System.Drawing.Point(176, 21)
        Me.cbx_testmode.Name = "cbx_testmode"
        Me.cbx_testmode.Size = New System.Drawing.Size(77, 17)
        Me.cbx_testmode.TabIndex = 4
        Me.cbx_testmode.Text = "Test Mode"
        Me.cbx_testmode.UseVisualStyleBackColor = True
        '
        'txt_payseq
        '
        Me.txt_payseq.Location = New System.Drawing.Point(140, 280)
        Me.txt_payseq.Name = "txt_payseq"
        Me.txt_payseq.Size = New System.Drawing.Size(54, 20)
        Me.txt_payseq.TabIndex = 5
        '
        'payseq_t
        '
        Me.payseq_t.AutoSize = True
        Me.payseq_t.Location = New System.Drawing.Point(48, 283)
        Me.payseq_t.Name = "payseq_t"
        Me.payseq_t.Size = New System.Drawing.Size(80, 13)
        Me.payseq_t.TabIndex = 6
        Me.payseq_t.Text = "Pay Sequence:"
        '
        'actgr_t
        '
        Me.actgr_t.AutoSize = True
        Me.actgr_t.Location = New System.Drawing.Point(42, 314)
        Me.actgr_t.Name = "actgr_t"
        Me.actgr_t.Size = New System.Drawing.Size(86, 13)
        Me.actgr_t.TabIndex = 7
        Me.actgr_t.Text = "Action Group ID:"
        '
        'txt_actgr
        '
        Me.txt_actgr.Location = New System.Drawing.Point(140, 309)
        Me.txt_actgr.Name = "txt_actgr"
        Me.txt_actgr.Size = New System.Drawing.Size(100, 20)
        Me.txt_actgr.TabIndex = 8
        '
        'txt_file
        '
        Me.txt_file.Location = New System.Drawing.Point(140, 336)
        Me.txt_file.Name = "txt_file"
        Me.txt_file.Size = New System.Drawing.Size(148, 20)
        Me.txt_file.TabIndex = 9
        '
        'file_t
        '
        Me.file_t.AutoSize = True
        Me.file_t.Location = New System.Drawing.Point(102, 342)
        Me.file_t.Name = "file_t"
        Me.file_t.Size = New System.Drawing.Size(26, 13)
        Me.file_t.TabIndex = 10
        Me.file_t.Text = "File:"
        '
        'GroupBox1
        '
        Me.GroupBox1.Controls.Add(Me.cbx_testmode)
        Me.GroupBox1.Location = New System.Drawing.Point(35, 258)
        Me.GroupBox1.Name = "GroupBox1"
        Me.GroupBox1.Size = New System.Drawing.Size(270, 112)
        Me.GroupBox1.TabIndex = 11
        Me.GroupBox1.TabStop = False
        Me.GroupBox1.Text = "Admin Use"
        '
        'dt_end
        '
        Me.dt_end.CustomFormat = "MMMM d, yyyy"
        Me.dt_end.Format = System.Windows.Forms.DateTimePickerFormat.Custom
        Me.dt_end.Location = New System.Drawing.Point(140, 50)
        Me.dt_end.Name = "dt_end"
        Me.dt_end.Size = New System.Drawing.Size(155, 20)
        Me.dt_end.TabIndex = 12
        '
        'enddate_t
        '
        Me.enddate_t.AutoSize = True
        Me.enddate_t.Location = New System.Drawing.Point(36, 54)
        Me.enddate_t.Name = "enddate_t"
        Me.enddate_t.Size = New System.Drawing.Size(97, 13)
        Me.enddate_t.TabIndex = 13
        Me.enddate_t.Text = "Pay Period Ending:"
        '
        'txt_status
        '
        Me.txt_status.Location = New System.Drawing.Point(38, 90)
        Me.txt_status.Multiline = True
        Me.txt_status.Name = "txt_status"
        Me.txt_status.ReadOnly = True
        Me.txt_status.ScrollBars = System.Windows.Forms.ScrollBars.Both
        Me.txt_status.Size = New System.Drawing.Size(284, 108)
        Me.txt_status.TabIndex = 16
        Me.txt_status.WordWrap = False
        '
        'mainForm
        '
        Me.AutoScaleDimensions = New System.Drawing.SizeF(6.0!, 13.0!)
        Me.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font
        Me.ClientSize = New System.Drawing.Size(359, 427)
        Me.Controls.Add(Me.txt_status)
        Me.Controls.Add(Me.enddate_t)
        Me.Controls.Add(Me.dt_end)
        Me.Controls.Add(Me.file_t)
        Me.Controls.Add(Me.txt_file)
        Me.Controls.Add(Me.txt_actgr)
        Me.Controls.Add(Me.actgr_t)
        Me.Controls.Add(Me.payseq_t)
        Me.Controls.Add(Me.txt_payseq)
        Me.Controls.Add(Me.b_cancel)
        Me.Controls.Add(Me.b_ok)
        Me.Controls.Add(Me.node_t)
        Me.Controls.Add(Me.cb_node)
        Me.Controls.Add(Me.GroupBox1)
        Me.Name = "mainForm"
        Me.Text = "Astea Payroll Transfer"
        Me.GroupBox1.ResumeLayout(False)
        Me.GroupBox1.PerformLayout()
        Me.ResumeLayout(False)
        Me.PerformLayout()

    End Sub
    Friend WithEvents cb_node As System.Windows.Forms.ComboBox
    Friend WithEvents node_t As System.Windows.Forms.Label
    Friend WithEvents b_ok As System.Windows.Forms.Button
    Friend WithEvents b_cancel As System.Windows.Forms.Button
    Friend WithEvents cbx_testmode As System.Windows.Forms.CheckBox
    Friend WithEvents txt_payseq As System.Windows.Forms.TextBox
    Friend WithEvents payseq_t As System.Windows.Forms.Label
    Friend WithEvents actgr_t As System.Windows.Forms.Label
    Friend WithEvents txt_actgr As System.Windows.Forms.TextBox
    Friend WithEvents txt_file As System.Windows.Forms.TextBox
    Friend WithEvents file_t As System.Windows.Forms.Label
    Friend WithEvents GroupBox1 As System.Windows.Forms.GroupBox
    Friend WithEvents dt_end As System.Windows.Forms.DateTimePicker
    Friend WithEvents enddate_t As System.Windows.Forms.Label
    Friend WithEvents txt_status As System.Windows.Forms.TextBox
End Class
