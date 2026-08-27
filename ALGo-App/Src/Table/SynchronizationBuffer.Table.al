table 50110 "ELCA CRM Sync. Buffer"
{
    Caption = 'CRM Synchronization Buffer';
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            AutoIncrement = true;
            Editable = false;
        }
        field(2; "CRM ID"; Guid)
        {
            Caption = 'CRM ID';
        }
        field(3; Direction; Integer)
        {
            Caption = 'Direction';
        }
        field(4; "Source Table ID"; Integer)
        {
            Caption = 'Source Table ID';
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
    }
}