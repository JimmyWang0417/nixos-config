# Composition only; host facts belong under hosts/, user settings under home/.
{ ... }:
{
  imports = [ ./core ./hardware ./desktop ./network ./services ./packages ./programs ];
}
