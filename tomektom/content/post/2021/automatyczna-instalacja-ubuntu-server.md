---
title: "Automatyczna Instalacja Ubuntu Server"
date: 2021-07-11T13:38:17+02:00
tags: 
  - ubuntu
  - linux
draft: false
---

Czasem może wystąpić potrzeba instalacji wielu maszyn z bardzo podobną konfiguracją. Z rozwiązaniami chmurowymi nie ma większego problemu – dostawcy często udostępniają odpowiednie narzędzia pozwalające w kilka chwil postawić taką maszynę – musimy tylko zapewnić konfigurację jakiej sobie życzymy. Podobnie z maszynami wirtualnymi – wystarczy modyfikacja pliku konfiguracyjnego albo odpowiednia komenda. Inaczej ma się sprawa z fizycznym sprzętem – tutaj trzeba zapewnić odpowiednio spreparowane ISO. Tutaj pokażę jak to zrobić na przykładzie Ubuntu Server 20.04.

<!--more-->

## Potrzebne narzędzia

Żeby zacząć musimy mieć z czym pracować, a więc pobieramy oficjalne iso Ubuntu Server ze strony [Ubuntu](https://ubuntu.com/download/server). Ponadto będziemy potrzebowali biblioteki `libisoburn`, która dostarczy program xorriso, który z kolei pozwoli utworzyć nasze iso oraz `syslinux`, który zapewni niezbędne bootloadery dla naszego iso.

Poza tym potrzebna będzie konfiguracja naszego systemu, znajdująca się w pliku `user-data`. Jest tego sporo, w dodatku całkiem dobrze opisane i opatrzone przykładami w dokumentacji, więc po prostu do niej odeślę:
- dokumentacji Ubuntu nt. [tworzenia konfiguracji](https://ubuntu.com/server/docs/install/autoinstall-reference)
- dokumentacji ubuntowego instalatora [curtin](https://curtin.readthedocs.io/en/latest/index.html)
- dokumentacji [cloud-init](https://cloudinit.readthedocs.io/en/latest/topics/modules.html) z którego Ubuntu w dużym stopniu korzysta, aczkolwiek należy mieć na uwadze, że nie wszystkie moduły będą działać

W razie problemów – zwłaszcza z dyskami – warto także zajrzeć do pliku `/var/log/installer/curtin-install-cfg.yaml`, który tworzy się po instalacji Ubuntu Server. Zawiera on automatycznie wygenerowaną konfigurację z której korzystał curtin.

## Procedura

Na samym początku trzeba utworzyć katalog w którym będziemy trzymać naszą konfigurację, a więc:
```bash
mkdir -p iso/nocloud/
```

Następnie trzeba rozpakować oficjalny obraz do świeżo utworzonego katalogu `iso`, można to zrobić na dwa sposoby. Polecam 7z, bo jest krótszy, drugi sposób załączam jako komentarz:
```bash
7z x ubuntu-20.04.2-live-server-amd64.iso -x'![BOOT]' -oiso
#xorriso -osirrox on -indev "ubuntu-20.04.2-live-server-amd64.iso" -extract / iso && chmod -R +w iso
```

Dopisujemy odpowiednie flagi do plików odpowiedzialnych za zabootowanie naszego iso, a więc:
```bash
sed -i 's|---|autoinstall ds=nocloud\\\;s=/cdrom/nocloud/ ---|g' iso/boot/grub/grub.cfg
sed -i 's|---|autoinstall ds=nocloud;s=/cdrom/nocloud/ ---|g' iso/isolinux/txt.cfg
```

Wyłączamy obowiązkowe sprawdzanie md5, jeśli tego nie zrobimy instalator odmówi nam zabootowania iso.
```bash
md5sum iso/.disk/info > iso/md5sum.txt
sed -i 's|iso/|./|g' iso/md5sum.txt
```

Teraz trzeba utworzyć da niezbędne pliki, których wymaga automatyczny instalator Ubuntu. Powinny się one znajdować w katalogu `iso/nocloud`, przy czym drugi z nich to jest nasza konfiguracja, którą wcześniej utworzyliśmy.
```bash
touch iso/nocloud/meta-data
cp user-data iso/nocloud/user-data
```

No i w końcu tworzymy iso. W zależności od tego na jakim systemie pracujecie komenda będzie się różnić, na Archu i pochodnych wygląda następująco:
```bash
xorriso -as mkisofs -r \
  -V Ubuntu\ custom\ amd64 \
  -o ubuntu-20.04.2-live-server-amd64-autoinstall.iso \
  -J -l -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot \
  -boot-load-size 4 -boot-info-table \
  -eltorito-alt-boot -e boot/grub/efi.img -no-emul-boot \
  -isohybrid-gpt-basdat -isohybrid-apm-hfsplus \
  -isohybrid-mbr /usr/lib/syslinux/bios/isohdpfx.bin  \
  iso/boot iso
```
natomiast na Debianie, Ubuntu i pokrewnych w konsolę wklepujemy takie coś:
```bash
xorriso -as mkisofs -r \
  -V Ubuntu\ custom\ amd64 \
  -o ubuntu-20.04.2-live-server-amd64-autoinstall.iso \
  -J -l -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot \
  -boot-load-size 4 -boot-info-table \
  -eltorito-alt-boot -e boot/grub/efi.img -no-emul-boot \
  -isohybrid-gpt-basdat -isohybrid-apm-hfsplus \
  -isohybrid-mbr /usr/lib/ISOLINUX/isohdpfx.bin  \
  iso/boot iso
```
I to wszystko, mamy gotowe iso. Warto tutaj zaznaczyć, że gdyby coś w naszym configu się nie podobało i chcielibyśmy coś zmienić nie trzeba powtarzać całej procedury. Wystarczy, że zmodyfikujemy `iso/nocloud/user-data` i powtórzymy ostatni krok.
