tableextension 50119 ServiceItem extends "Service Item"
{
    AllowInCustomizations = AsReadOnly;

    fields
    {
        // Add changes to table fields here
        field(50102; FunctionalLocationID; GUID)
        {

            Description = 'Poste technique de l’ordre de travail';
            Caption = 'Poste technique';
            FieldClass = Normal;
            ObsoleteState = Removed;
            ObsoleteReason = 'Remove';
            trigger OnValidate()
            var
                ServiceHeaderRef: RecordRef;
                ShipToCode: Code[20];
            begin
                // ServiceHeaderRef := Rec;
                // shiptoAddressCodeunit.RetriveFunctionalLocationCode(ServiceHeaderRef, ShipToCode);
                // Rec.Validate("Ship-to Code", ShipToCode);
            end;

        }


        field(50101; "Description Supp."; Text[500])
        {
            Caption = 'Description Supp.';
            //DataClassification = CustomerContent; // Utilise approprié: CustomerContent, ToBeClassified, etc.
        }
        field(50100; msdyn_customerassetId; GUID)
        {
            Description = 'Affiche les instances de l''entité.';
            Caption = 'Actif du client';
        }
        field(50103; "Date installation actif"; DateTime)
        {
            Caption = 'Date d’installation actif';

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