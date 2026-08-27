tableextension 50114 ItemLedgerEntry extends "Item Ledger Entry"
{
    AllowInCustomizations = AsReadOnly;

    fields
    {
        // Add changes to table fields here
        field(50100; "N° de l’intervention"; Code[20])
        {
            ObsoleteState = Removed;
            ObsoleteReason = 'Replaced by Text[100] field.';
        }

        field(50101; TechnitianName; Code[20])
        {
            Caption = 'Nom du technicien';
            ObsoleteState = Removed;
            ObsoleteReason = 'Replaced by Text[100] field.';

        }
        field(50102; "No de intervention"; Text[100])
        {
            Caption = 'N° de l’intervention';
        }
        field(50103; "Technitian Name"; Text[100])
        {
            Caption = 'Nom du technicien';

        }
        field(50104; "Phma source Document Order No"; Code[20])
        {

        }
        field(50105; "Phma Customer Name"; Text[100])
        {

        }
        field(50106; "Phma document order type"; Text[100])
        {

        }
        field(50107; "TenantName"; Text[100])
        {
            Caption = 'Nom du Locataire';
            DataClassification = ToBeClassified;
        }
        field(50108; Instructions; Text[100])
        {
            DataClassification = ToBeClassified;
        }
    }

    keys
    {
        // Add changes to keys here
    }

    fieldgroups
    {
        // Add changes to field groups here
    }

}