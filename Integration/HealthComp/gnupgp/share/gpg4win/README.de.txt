
                  Deutsche README Datei f�r Gpg4win
                  =================================

Dies ist Gpg4win, Version 2.2.1 (2013-10-07).

Inhalt:

     1. Wichtige Hinweise
     2. �nderungen
     3. Bekannte Probleme (und Abhilfen)
     4. Installation
     5. Versionshistorie
     6. Versionsnummern der einzelnen Programmteile
     7. Rechtliche Hinweise


1. Wichtige Hinweise
====================

Hilfe bei der Installation und Benutzung von Gpg4win bietet Ihnen das
Gpg4win-Kompendium. Sie finden es nach der Installation im
Gpg4win-Startmen� unter 'Dokumentation' oder direkt online unter:
http://www.gpg4win.de/doc/de/gpg4win-compendium.html

Falls Sie von Gpg4win 1.x oder einem andern Proramm auf Gpg4win 2.x
umsteigen wollen, beachten Sie bitte die Migrationshinweise im Anhang
des Gpg4win-Kompendiums:
http://www.gpg4win.de/doc/de/gpg4win-compendium_36.html

Bitte lesen Sie den Abschnitt "3. Bekannte Probleme (und Abhilfen)"
dieses READMEs, bevor Sie beginnen Gpg4win zu nutzen.

Gpg4win unterst�tzt folgende Plattformen:

  * Betriebssystem: Windows XP, Vista, 7, 8 (f�r alle: 32/64 bit)

  * MS Outlook: 2003, 2007, 2010, 2013


2. �nderungen
=============

Die integrierten Gpg4win-Komponenten in Version 2.2.1 sind:

    GnuPG:          2.0.22
    Kleopatra:      2.2.0
    GPA:            0.9.4
    GpgOL:          1.2.0
    GpgEX:          1.0.0
    Claws-Mail:     3.9.1
    Kompendium DE:  3.0.0
    Kompendium EN:  3.0.0


Neu in Gpg4win Version 2.2.1 (2013-10-07)
-------------------------------------------------

- GnuPG:
  * Ein Fehler welche m�gliche endlosschleife in GnuPG ausl�sen
    konnte wurde behoben. [CVE-2013-4402]

  * Unterst�tzung f�r SPR332 und 532 Pinpads.

- Kleopatra:
  * Ein Absturz des Programms wurde behoben der auftrat wenn Microsoft Office
    IME verwendet wurde


3. Bekannte Probleme (und Abhilfen)
===================================

- Smartcard-Nutzung mit Kleopatra

   Die Einrichtung von Smartcards unter Kleopatra ist derzeit noch
   nicht vollst�ndig m�glich. Bitte f�hren Sie folgende Schritte
   einmalig durch, um Ihre Smartcard anschlie�end unter Kleopatra
   nutzen zu k�nnen.

   * OpenPGP Karte
     Verwenden Sie das gpg-Kommandozeilen-Werkzeug, um ein neues
     OpenPGP-Zertifikat auf Ihrer Karte zu erzeugen (a) oder Ihr
     vohandenes Zertifikat von Ihrer Karte zu aktivieren (b):

     (a) Neues Zertifikat erzeugen
       - Karte einlegen.
       - F�hren Sie "gpg --card-edit" auf der Kommandozeile aus.
       - Wechseln Sie in den Admin-Modus mit "admin".
       - Geben Sie "generate" ein und folgen Sie den Anweisungen, um
         ein neues Zertifiakt zu erzeugen.

     (b) Vorhandenes Zertifikat von der Karte aktivieren
       - Das (zu der Karte) zugeh�rige �ffentliche Zertifikat
         importieren (z.B. von einem Zertifikatsserver oder von einer
         vorher exportierten Zertifikatsdatei).
       - Karte einlegen.
       - F�hren Sie "gpg --card-status" auf der Kommandozeile aus.

   * X.509 Telesec Netkey 3 Karte
     Verwenden Sie Kleopatra, um Ihre Karte (einmalig) zu initialisieren:
     - Karte einlegen.
     - Auf das blinkende Kleopatra-Smartcard-Systemtray-Icon klicken
       (oder direkt das Systemtray-Kontextmen� "Smartcard" und dort
       den "LearnCard"-Eintrag aufrufen).

   Anschlie�end wird Ihr OpenPGP- bzw. X.509-Smartcard-Zertifikat in
   Kleopatra unter dem Reiter "Meine Zertifikate" angezeigt (markiert
   mit einem Smartcard-Icon).

- Verwendung der Outlook-Programmerweiterung "GpgOL":

  * Sie sollten unbedingt vor der Installation von GpgOL
    Sicherheitskopien Ihrer alten verschl�sselten/signierten E-Mails
    erstellen, z.B. in PST-Dateien!

  * Nur f�r Outlook 2003/2007:
    Senden von signierten oder verschl�sselten Nachrichten �ber ein
    Exchange-basiertes Konto funktioniert nicht.
    [siehe https://bugs.g10code.com/gnupg/issue1102]
    (Hinweis: Beim Verwenden von SMTP sollte das Senden
     mit GpgOL funktionieren. Oder Sie nutzen GpgOL mit Outlook
    2010/2013.)

  * Nur f�r Outlook 2003/2007:
    Verschl�sselte E-Mails unverschl�sselt auf E-Mail-Server:
    Es kann vorkommen, dass Teile von verschl�sselten E-Mails
    in entschl�sselter/unverschl�sselter Form auf dem E-Mail-Server
    (IMAP oder MAPI) zu liegen kommen, wenn man sie erstellt/liest.
    Betroffen sind nur der Inhalt des Anzeigefensters von Outlook,
    also der "E-Mail-Body".  Anh�nge sind nicht betroffen.
    Schaltet man die Voransicht von Outlook ab, so
    verringert sich die Wahrscheinlichkeit daf�r deutlich,
    aber es kann trotzdem noch passieren. Oder Sie nutzen GpgOl mit
    Outlook 2010/2013.


4. Installation
===============

Eine Anleitung zur Installation von Gpg4win finden Sie im Gpg4win-Kompendium:
http://www.gpg4win.de/doc/de/gpg4win-compendium_11.html

Hinweise zur automatisierten Installation (ohne Benutzerdialoge)
finden Sie im Anhang des Gpg4win-Komendiums:
http://www.gpg4win.de/doc/de/gpg4win-compendium_35.html


5. Versionsgeschichte
=====================

Eine aktuelle deutschsprachige �bersicht der �nderungen finden Sie online
unter: http://www.gpg4win.de/change-history-de.html
Im weiteren finden Sie die Eintr�ge aus der englischen NEWS-Datei:


Noteworthy changes in version 2.2.1 (2013-10-08)
------------------------------------------------

   * Fixed possible infinite recursion in the compressed packet
   parser. [CVE-2013-4402]

   * Kleopatra no longer crashes when using Microsoft Office IME.

   * Support for SPR332 and 532 pinpads.

~~~~~~~~~~~~~~~
GnuPG:          2.0.22
Kleopatra:      2.2.0
GPA:            0.9.4
GpgOL:          1.2.0
GpgEX:          1.0.0
Claws-Mail:     3.9.1
Kompendium DE:  3.0.0
Kompendium EN:  3.0.0
~~~~~~~~~~~~~~~


Noteworthy changes in version 2.2.0 (2013-08-20)
------------------------------------------------

   * GpgEx now works on Windows 64 bit.

   * Gpg-agent may now be used as Pageant (PuTTY authentication agent)
     replacement with additional smartcard support.

   * Pinentry now allows to paste in the passphrase.

   * Kleopatra no longer crashes when started by a regular user on
     terminal servers (Windows Server).

   * GpgOL provides rudimentary support for Outlook 2010 and 2013.
     The following crypto functions are already available via the new
     GpgOL ribbon rsp. Outlook's context menu (no MIME parsing, yet):
     - Encrypting/decrypting mail bodys
     - Saving and decrypting attachments
     - Attaching and encrypting files
     - Signing and signature verification (of opaque signatures)

   * Extracting a tarball through the Kleopatra GUI now works reliable

   * Added mkportable.exe as a tool to create a portable installation.

   * Kleopatra now allows it to generate keys with a size up to 4096 bit.

~~~~~~~~~~~~~~~
GnuPG:          2.0.21
Kleopatra:      2.2.0
GPA:            0.9.4
GpgOL:          1.2.0
GpgEX:          1.0.0
Claws-Mail:     3.9.1
Kompendium DE:  3.0.0
Kompendium EN:  3.0.0
~~~~~~~~~~~~~~~


Noteworthy changes in version 2.1.1 (2013-05-28)
------------------------------------------------

   * New versions of GnuPG, GpgOL, GPA, Kleopatra, and Claws-Mail.

   * Development files for the crypto libraries will now be installed.

~~~~~~~~~~~~~~~
GnuPG:          2.0.20
Kleopatra:      2.1.1
GPA:            0.9.4
GpgOL:          1.1.3
GpgEX:          0.9.7
Claws-Mail:     3.9.1
Kompendium DE:  3.0.0
Kompendium EN:  3.0.0-beta1
~~~~~~~~~~~~~~~


Noteworthy changes in version 2.1.0 (2011-03-15)
------------------------------------------------

   * New versions of GnuPG, Kleopatra, GpgEX, GpgOL, Claws.

~~~~~~~~~~~~~~~
GnuPG:          2.0.17
Kleopatra:      2.1.0 (2011-02-04)
GPA:            0.9.1-svn1024
GpgOL:          1.1.2
GpgEX:          0.9.7
Claws-Mail:     3.7.8cvs47
Kompendium DE:  3.0.0
Kompendium EN:  3.0.0-beta1
~~~~~~~~~~~~~~~


Noteworthy changes in version 2.0.4 (2010-07-28)
------------------------------------------------

   * GpgSM bug fix.

~~~~~~~~~~~~~~~
GnuPG:        2.0.14 + 02-gpgsm-realloc-bug.patch
Kleopatra:    2.0.14-svn1098530 (20100303)
GPA:          0.9.0
GpgOL:        1.1.1
GpgEX:        0.9.5
Claws-Mail:   3.7.4cvs1
Kompendium:   3.0.0
~~~~~~~~~~~~~~~


Noteworthy changes in version 2.0.3 (2010-05-29)
------------------------------------------------

   * Bug fixes.

~~~~~~~~~~~~~~~
GnuPG:        2.0.14
Kleopatra:    2.0.14-svn1098530 (20100303)
GPA:          0.9.0
GpgOL:        1.1.1
GpgEX:        0.9.5
Claws-Mail:   3.7.4cvs1
Kompendium:   3.0.0
~~~~~~~~~~~~~~~


Noteworthy changes in version 2.0.2 (2010-04-12)
------------------------------------------------

   * Bug fixes and UI improvements.

~~~~~~~~~~~~~~~
GnuPG:        2.0.14
Kleopatra:    2.0.14-svn1098530 (20100303)
GPA:          0.9.0
GpgOL:        1.1.1
GpgEX:        0.9.5
Claws-Mail:   3.7.4cvs1
Kompendium:   3.0.0-rc1
~~~~~~~~~~~~~~~


Noteworthy changes in version 2.0.1 (2009-09-28)
------------------------------------------------

   * Fixed a problem opening Office documents and URLs with a running
     GpgOL.

~~~~~~~~~~~~~~~
GnuPG:        2.0.12
Kleopatra:    2.0.11-svn1008232 (2009-09-25)
GPA:          0.9.0
GpgOL:        1.0.1
GpgEX:        0.9.3
Claws-Mail:   3.7.2cvs27
Kompendium:   3.0.0-beta4
~~~~~~~~~~~~~~~



Noteworthy changes in version 2.0.0 (2009-08-07)
------------------------------------------------

   * First production release of this major redesign.  Over the last
     15 months we did 15 beta releases and hopefully squashed most of
     the serious bugs.

~~~~~~~~~~~~~~~
GnuPG:        2.0.12
Kleopatra:    20090807
GPA:          0.9.0
GpgOL:        1.0.0
GpgEX:        0.9.3
Claws-Mail:   3.7.2
Kompendium:   3.0.0-beta3
~~~~~~~~~~~~~~~


For older news see the file ONEWS in the source distribution.



6. Versionsnummern der einzelnen Programmteile
==============================================

Zur �bersicht sind hier die Pr�fsummen sowie die Namen der einzelnen
Bestandteile aufgelistet.

=========== SHA-1 checksum ============= == package ==
ef483090edcdd85ae672aa3bab21526b1e335ae3 adns-1.4-g10-3.tar.bz2
3c31c9d6b19af840e2bd8ccbfef4072a6548dc4e atk-1.32.0.zip
d0b8c53e01e4541d3d3befc82e41fb5b84949030 atk-dev-1.32.0.zip
6e38be3377340a21a1f13ff84b5e6adce97cd1d4 bzip2-1.0.6-g10.tar.gz
d44cd66a9f4d7d29a8f2c28d1c1c5f9b0525ba44 cairo-1.10.2.zip
45cae1fac45a6c6f33498c37c0cdc47722614d92 cairo-dev-1.10.2.zip
ec3a787b34b07983d938f7d353e3cfd85167122b claws-mail-3.9.1.tar.bz2
04b4c2ac296499d378f4a35bbeb1b129165b2e61 crypt-1.1.tar.gz
23fdc215558023b943cea9dfab04b86020037b0d curl-7.30.0.tar.bz2
59abdc742ce87011dadbc58e96ed870a927d0045 dbus-x86-mingw4-1.4.24-20130417-1-bin.tar.bz2
fc557d7eb161881e1d6c091f215dd8e0615682cb dbus-x86-mingw4-1.4.24-20130417-lib.tar.bz2
e708d4aa5ce852f4de3f4b58f4e4f221f5e5c690 dirmngr-1.1.1.tar.bz2
321f9cf0abfa1937401676ce60976d8779c39536 enchant-1.6.0.tar.gz
f47790b9e324cd8613acc9a17fd56bf2c14745fc expat-2.0.1.zip
2e9189c6c6d1dac847a47c537c7a5e9dffd91992 expat-dev-2.0.1.zip
37a3117ea6cc50c8a88fba9b6018f35a04fa71ce fontconfig-2.8.0.zip
0b772aaeb0a7a0d5de21afd901d6cf00753efa51 fontconfig-dev-2.8.0.zip
c20ab9ff053fe59f73612fd392f6e6dc01af614a freetype-2.4.2.zip
00e877d7ec7c416e2b48a392324a5502019a20bf freetype-dev-2.4.2.zip
94f30c417441404dcbe23206dda91730074f9b7d gdk-pixbuf-2.26.5.tar.xz
86066950cac2fcc49cc7bd23f5ea16bed522b410 gettext-0.18.2.1.tar.gz
f2b94ca757191dddba686e54b32b3dfc5ad5d8fb glib-2.34.3.tar.xz
9ba9ee288e9bf813e0f1e25cbe06b58d3072d8b8 gnupg2-2.0.22.tar.bz2
a02bef78c7e35217d84d36d9b3135de70b46be09 gnutls-2.12.21.tar.bz2
d4b22b6d1f0ce25244c5a001e3bcbc36aff13ecf gpa-0.9.4.tar.bz2
32217457b0c9a3eeb544833be85dc9a9702a45d3 gpgex-1.0.0.tar.bz2
ffdb5e4ce85220501515af8ead86fd499525ef9a gpgme-1.4.3.tar.bz2
a263bb7d363c24b521cd6120492c5b8e0ebe10b9 gpgol-1.2.0.tar.bz2
1c539a1564fbcb0a9b60b03188dc808f7b678531 gtk+-2.24.17.tar.xz
7f3f8a9e3f7bec443a51c890d1bbcd26049dde02 gtkhtml2_viewer-0.34.tar.gz
b0b14b0de25a8855ff083cc0e7c9f3efde5c3f1b kleopatra-20130829-bin.tar.bz2
8bd3826de30651eb8f9b8673e2edff77cd70aca1 libassuan-2.1.1.tar.bz2
d7195498005d340ccd82e183de19163d16e56ec2 libetpan-0.58-g10-1.tar.bz2
f5230890dc0be42fb5c58fbf793da253155de106 libffi-3.0.13.tar.gz
2c6553cc17f2a1616d512d6870fe95edf6b0e26e libgcrypt-1.5.3.tar.bz2
259f359cd1440b21840c3a78e852afd549c709b8 libgpg-error-1.12.tar.bz2
08fd5dfdd3d88154cf06cb0759a732790c47b4f7 libgsasl-1.8.0.tar.gz
be7d67e50d72ff067b2c0291311bc283add36965 libiconv-1.14.tar.gz
241afcb2dfbf3f3fc27891a53a33f12d9084d772 libksba-1.3.0.tar.bz2
275cfa90c0558601f6216019317fc37a03ebee01 libpng-1.4.12.tar.bz2
22f9e0b15f870c8e03ac9cc1ead969d4d84eb931 libtasn1-2.14.tar.gz
859dd535edbb851cc15b64740ee06551a7a17d40 libxml2-2.7.8.tar.gz
653870001dd4a477ad064420d0ce08f0d023a734 oxygen-icons-20130515-bin.tar.bz2
3959319bd04fbce513458857f334ada279b8cdd4 pango-1.29.4.zip
49ae12458f2e29c27ed9d1390d95db18fd4a49ac pango-dev-1.29.4.zip
16af56d0e7bdf081d60c59ea4d72e7df6d9cec21 paperkey-1.3.tar.gz
de4ba5ef9a1ced4e4f8543feac553d4cf68dea00 pinentry-0.8.4-beta8.tar.bz2
d063e705812e1ee7feb8f35d51b3cad04ca13b0d pkgconfig-0.23.zip
da8371cb20e8e238f96a1d0651212f154d84a9ac pthreads-w32-2-8-0-release.tar.gz
7bb89e83cacfd69b01aa7e607bf8f9be61e9ba8c qt-x86-mingw4-4.8.4-20130514-bin.tar.bz2
0d698cdf3a35575d982f2c351e00e49a45fcd638 qt-x86-mingw4-4.8.4-20130514-lib.tar.bz2
56c87366f49916997729fc335747a6a55a2bacc3 regex-20090805.tar.gz
e28141d2b03612c09512651795976c58ed3f8035 scute-1.4.0.tar.bz2
d648b98ce215f81e901f3f982470d37c704433a6 w32pth-2.0.5.tar.bz2
a4d316c404ff54ca545ea71a27af7dbc29817088 zlib-1.2.8.tar.gz


7. Rechtliche Hinweise zu den einzelnen Bestandteilen der Software
==================================================================

Gpg4win besteht aus einer ganzen Reihe von unabh�ngig entwickelten
Packeten, die teilweise unterschiedliche Lizenzen haben.  Der Gro�teil
dieser Software ist, wie Gpg4win selbst, steht unter der GNU General
Public License (GNU GPL).  Gemeinsam ist, dass die Software ohne
Restriktionen benutzt werden kann, ver�ndert werden darf und
�nderungen weitergeben d�rfen.  Wenn die Quelltexte (also
gpg4win-x.y.z.tar.bz2) mit weitergegeben werden und auf die die GNU
GPL hingewiesen wird, ist die Weitergabe in jedem Fall m�glich.

Zur �bersicht folgt eine Liste der Copyright Erkl�rungen.


Here is a list with collected copyright notices.  For details see the
description of each individual package.  This is not meant as an
exhaustive list of copyright notices.  Notices from several packages
are even not listed.  The most restrictive requirements are those of
the GNU General Public License version 3 (GPLv3+); thus complying to
those terms and conditions should be sufficient.  If in doubt check
the individual packages.


Gpg4win (the installer) is

  Copyright (C) 2005, 2006, 2007, 2008, 2009, 2010, 2013 g10 Code GmbH

  Gpg4win is free software; you can redistribute it and/or modify it
  under the terms of the GNU General Public License as published by
  the Free Software Foundation; either version 2 of the License, or
  (at your option) any later version.

  Gpg4win is distributed in the hope that it will be useful, but
  WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
  General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program; if not, write to the Free Software
  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
  02110-1301, USA


GnuPG is

  Copyright 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,
            2006, 2007, 2008, 2009, 2010, 2011, 2012,
            2013 Free Software Foundation, Inc.

  GnuPG is free software; you can redistribute it and/or modify it
  under the terms of the GNU General Public License as published by
  the Free Software Foundation; either version 3 of the License, or
  (at your option) any later version.

  GnuPG is distributed in the hope that it will be useful, but WITHOUT
  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
  or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public
  License for more details.

  You should have received a copy of the GNU General Public License
  along with this program; if not, see <http://www.gnu.org/licenses/>.

  See the files AUTHORS and THANKS for credits, further legal
  information and bug reporting addresses pertaining to GnuPG.


NSIS is

  Copyright 1999-2009 Nullsoft, Jeff Doozan and Contributors
  Copyright 2002-2008 Amir Szekely
  Copyright 2003 Ramon
  Copyright 1995-1998 Jean-loup Gailly and Mark Adler
  Copyright 1999-2006 Igor Pavlov
  Copyright 1996-2000 Julian R Seward

  This license applies to everything in the NSIS package, except where
  otherwise noted.

  This software is provided 'as-is', without any express or implied
  warranty. In no event will the authors be held liable for any
  damages arising from the use of this software.

  Permission is granted to anyone to use this software for any
  purpose, including commercial applications, and to alter it and
  redistribute it freely, subject to the following restrictions:

  1. The origin of this software must not be misrepresented; you must
     not claim that you wrote the original software. If you use this
     software in a product, an acknowledgment in the product
     documentation would be appreciated but is not required.

  2. Altered source versions must be plainly marked as such, and must
     not be misrepresented as being the original software.

  3. This notice may not be removed or altered from any source
     distribution.

  The user interface used with the installer is

  Copyright (C) 2002-2005 Joost Verburg

  [It is distributed along with NSIS and the same conditions as stated
   above apply]


GLIB is

  Copyright (C) 1995-1997 Peter Mattis, Spencer Kimball and Josh MacDonald
  Copyright (C) 1995-2011 Red Hat, Inc.
  Copyright (C) 2008-2010 Novell, Inc.
  Copyright (C) 2008-2010 Codethink Limited.
  Copyright (C) 2008-2010 Collabora, Ltd.

  This library is free software; you can redistribute it and/or
  modify it under the terms of the GNU Lesser General Public
  License as published by the Free Software Foundation; either
  version 2 of the License, or (at your option) any later version.

  This library is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	 See the GNU
  Lesser General Public License for more details.

  You should have received a copy of the GNU Lesser General Public
  License along with this library; if not, write to the
  Free Software Foundation, Inc., 59 Temple Place - Suite 330,
  Boston, MA 02111-1307, USA.

  See the AUTHORS file for a list of people on the GLib Team.  See the
  ChangeLog files for a list of changes.  These files are distributed
  with GLib at ftp://ftp.gtk.org/pub/gtk/.


GPA is

  Copyright (C) 2000-2002 G-N-U GmbH (http://www.g-n-u.de)
  Copyright (C) 2002-2003 Miguel Coca.
  Copyright (C) 2005-2013 g10 Code GmbH

  GPA uses fragments from the following programs and libraries:
  JNLIB, Copyright (C) 1998-2000 Free Software Foundation, Inc.
  GPGME, Copyright (C) 2000-2001 Werner Koch
  WinPT, Copyright (C) 2000-2002 Timo Schulz
  (For details, see the file `AUTHORS'.)

  GPA is free software; you can redistribute it and/or modify it
  under the terms of the GNU General Public License as published by
  the Free Software Foundation; either version 3 of the License, or
  (at your option) any later version.

  GPA is distributed in the hope that it will be useful, but
  WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program; if not, see <http://www.gnu.org/licenses/>.


GPGEX is

  Copyright (C) 2007 g10 Code GmbH

  GpgEX is free software; you can redistribute it and/or
  modify it under the terms of the GNU Lesser General Public
  License as published by the Free Software Foundation; either
  version 2 of the License, or (at your option) any later version.

  GpgEX is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
  GNU Lesser General Public License for more details.

  You should have received a copy of the GNU Lesser General Public
  License along with this program; if not, write to the Free Software
  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
  02110-1301, USA.


GPGME is

  Copyright (C) 2000 Werner Koch
  Copyright (C) 2001--2013 g10 Code GmbH

  GPGME is free software; you can redistribute it and/or modify it
  under the terms of the GNU Lesser General Public License as
  published by the Free Software Foundation; either version 2.1 of
  the License, or (at your option) any later version.

  GPGME is distributed in the hope that it will be useful, but
  WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
  Lesser General Public License for more details.

  You should have received a copy of the GNU Lesser General Public
  License along with this program; if not, see <http://www.gnu.org/licenses/>.

  See the files AUTHORS and THANKS for credits, further legal
  information and bug reporting addresses pertaining to GPGME.


GpgOL is

  Copyright (C) 2004, 2005, 2007, 2008, 2009, 2010,
                2011 g10 Code GmbH

  GpgOL is free software; you can redistribute it and/or
  modify it under the terms of the GNU Lesser General Public
  License as published by the Free Software Foundation; either
  version 2 of the License, or (at your option) any later version.

  GpgOL is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
  GNU Lesser General Public License for more details.

  You should have received a copy of the GNU Lesser General Public
  License along with this program; if not, see <http://www.gnu.org/licenses/>.

  See the files AUTHORS and THANKS for credits, further legal
  information and bug reporting addresses pertaining to GpgOL.


GTK+ is

  Copyright (C) 1995-1997 Peter Mattis, Spencer Kimball and Josh MacDonald

  This library is free software; you can redistribute it and/or
  modify it under the terms of the GNU Lesser General Public
  License as published by the Free Software Foundation; either
  version 2 of the License, or (at your option) any later version.

  This library is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
  Lesser General Public License for more details.

  You should have received a copy of the GNU Lesser General Public
  License along with this library; if not, write to the
  Free Software Foundation, Inc., 59 Temple Place - Suite 330,
  Boston, MA 02111-1307, USA.

  Modified by the GTK+ Team and others 1997-2000.  See the AUTHORS
  file for a list of people on the GTK+ Team.  See the ChangeLog
  files for a list of changes.  These files are distributed with
  GTK+ at ftp://ftp.gtk.org/pub/gtk/.


LIBGCRYPT is

  Copyright 2000, 2002, 2003, 2004, 2007, 2008, 2009,
            2010, 2011, 2012 Free Software Foundation, Inc.
  Copyright 2012, 2013 g10 Code GmbH

  Libgcrypt is free software; you can redistribute it and/or modify
  it under the terms of the GNU Lesser general Public License as
  published by the Free Software Foundation; either version 2.1 of
  the License, or (at your option) any later version.

  Libgcrypt is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU Lesser General Public License for more details.

  You should have received a copy of the GNU Lesser General Public
  License along with this program; if not, see <http://www.gnu.org/licenses/>.


LIBGPG-ERROR is

  Copyright 2003, 2004, 2010, 2013 g10 Code GmbH

  libgpg-error is free software; you can redistribute it and/or
  modify it under the terms of the GNU Lesser General Public License
  as published by the Free Software Foundation; either version 2.1 of
  the License, or (at your option) any later version.

  libgpg-error is distributed in the hope that it will be useful, but
  WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
  Lesser General Public License for more details.

  You should have received a copy of the GNU Lesser General Public
  License along with this program; if not, see <http://www.gnu.org/licenses/>.


Pthreads-win32 is

  Copyright(C) 1998 John E. Bossom
  Copyright(C) 1999,2005 Pthreads-win32 contributors

  Most of this is work available under the GNU Lesser General Public
  License as published by the Free Software Foundation version 2.1 of
  the License.  The detailed terms are given in the file COPYING in
  the source distribution; that very file may not be modified and thus
  it is not possible to include it here.


Claws Mail is

  Copyright(C) 1999-2013 Hiroyuki Yamamoto <hiro-y@kcn.ne.jp> and the
  Claws Mail Team

  This program is free software; you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation; either version 3, or (at your option)
  any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program; if not, write to the Free Software
  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
  02110-1301, USA.

  For more details see the file COPYING.


BZIP2 is

  This program, "bzip2", the associated library "libbzip2", and all
  documentation, are copyright (C) 1996-2006 Julian R Seward.  All
  rights reserved.

  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions
  are met:

  1. Redistributions of source code must retain the above copyright
     notice, this list of conditions and the following disclaimer.

  2. The origin of this software must not be misrepresented; you must
     not claim that you wrote the original software.  If you use this
     software in a product, an acknowledgment in the product
     documentation would be appreciated but is not required.

  3. Altered source versions must be plainly marked as such, and must
     not be misrepresented as being the original software.

  4. The name of the author may not be used to endorse or promote
     products derived from this software without specific prior written
     permission.

  THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS
  OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
  ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
  DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
  DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
  GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
  WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

  Julian Seward, Cambridge, UK.
  jseward@bzip.org
  bzip2/libbzip2 version 1.0.4 of 20 December 2006


ADNS

  adns is Copyright 2008 g10 Code GmbH, Copyright 1997-2000,2003,2006
  Ian Jackson, Copyright 1999-2000,2003,2006 Tony Finch, and Copyright
  (C) 1991 Massachusetts Institute of Technology.

  adns is free software; you can redistribute it and/or modify it
  under the terms of the GNU General Public License as published by
  the Free Software Foundation; either version 2 of the License, or
  (at your option) any later version.

  This program and documentation is distributed in the hope that it will
  be useful, but without any warranty; without even the implied warranty
  of merchantability or fitness for a particular purpose. See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with adns, or one should be available above; if not, write to
  the Free Software Foundation, 59 Temple Place - Suite 330, Boston,
  MA 02111-1307, USA, or email adns-maint@chiark.greenend.org.uk.


Paperkey

  Copyright (C) 2007, 2008, 2009 David Shaw <dshaw@jabberwocky.com>

  This program is free software; you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation; either version 2 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program; if not, write to the Free Software
  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
  MA 02110-1301, USA.

  The included man page is

  Copyright (C) 2007 Peter Palfrader <peter@palfrader.org>

  Examples have been taken from David Shaw's README. The license is
  the same as for Paperkey.


Scute

  Copyright 2006, 2008 g10 Code GmbH

  Scute is licensed under the GNU General Pubic License, either
  version 2, or (at your option) any later version with this special
  exception:

  In addition, as a special exception, g10 Code GmbH gives permission
  to link this library: with the Mozilla Foundation's code for
  Mozilla (or with modified versions of it that use the same license
  as the "Mozilla" code), and distribute the linked executables.  You
  must obey the GNU General Public License in all respects for all of
  the code used other than "Mozilla".  If you modify the software, you
  may extend this exception to your version of the software, but you
  are not obligated to do so.  If you do not wish to do so, delete this
  exception statement from your version and from all source files.


[Compiled by wk 2006-02-15, last updated 2013-05-13]




Viel Erfolg,

  Ihr Gpg4win Team


*** Ende der Datei ***
