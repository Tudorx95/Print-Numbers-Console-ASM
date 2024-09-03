
### A simple convertor from Binary numbers to Octal, Decimal, or Hexadecimal bases ###

***Preparing the script***: 

  nasm -f elf32 Convertor_Bin_Dec.asm -o Convertor_Bin_Dec.o
  
  ld -m elf_i386 Convertor_Bin_Dec.o -o Convertor_Bin_Dec

***Running the executable***:

  ./Convertor_Bin_Dec

  
