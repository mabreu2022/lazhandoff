{ This file was automatically created by Lazarus. Do not edit!
  This source is only used to compile and install the package.
 }

unit laz_eng_components_dt;

{$warn 5023 off : no warning about unused units}
interface

uses
  LazPackageRegister, LazarusPackageIntf;

implementation

procedure Register;
begin
  RegisterUnit('LazPackageRegister', @LazPackageRegister.Register);
end;

initialization
  RegisterPackage('laz_eng_components_dt', @Register);
end.
