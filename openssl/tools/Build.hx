import haxe.io.Path;
import hxcpp.Builder;
import sys.FileSystem;
import sys.io.File;

class Build extends Builder
{
   var buildArgs:Array<String>;

   override public function allowNdll() { return false; }

   override public function runBuild(target:String, isStatic:Bool, arch:String, inBuildFlags:Array<String>)
   {
      if (!isStatic)
         return;

      var android = target=="android";
      var ios = target=="ios";
      var blackberry = target=="blackberry";
      var tizen = target=="tizen";
      var emscripten = target=="emscripten";
      var webos = target=="webos";

      buildArgs = inBuildFlags;

      if (verbose)
         Sys.println('Build $target $isStatic $android ' + buildArgs);

      mkdir("bin");
      mkdir("unpack");
      mkdir("../include");
      
      if (emscripten)
      {
         return;
      }

      buildSsl("1.0.2g");
   }

   override public function cleanAll(inBuildFlags:Array<String>) : Bool
   {
      Builder.deleteRecurse("unpack");
      return true;
   }

   public static function mkdir(inDir:String)
   {
      FileSystem.createDirectory(inDir);
   }

   public static function untar(inCheckDir:String,inTar:String,inBZ = false,baseDir="unpack")
   {
      if (inCheckDir!="")
      {
         if (FileSystem.exists(inCheckDir+"/.extracted"))
            return;
      }
      Sys.println("untar " + inTar);
      run("tar", [ inBZ ? "xf" : "xzf", "tars/" + inTar, "--no-same-owner", "-C", baseDir ]);
      if (inCheckDir!="")
         File.saveContent(inCheckDir+"/.extracted","extracted");
   }

   public static function run(inExe:String, inArgs:Array<String>)
   {
      trace(inExe + " " + inArgs.join(" "));
      var result = Sys.command(inExe,inArgs);
      if (result != 0)
      {
         Sys.exit(result);
      }
   }

   public static function copy(inFrom:String, inTo:String)
   {
      if (FileSystem.exists(inTo) && FileSystem.isDirectory(inTo))
         inTo += "/" + haxe.io.Path.withoutDirectory(inFrom);

      if (FileSystem.exists(inFrom) && FileSystem.exists(inTo))
      {
         if (File.getContent(inFrom)==File.getContent(inTo))
            return;
      }

      try {
         sys.io.File.copy(inFrom,inTo);
      }
      catch(e:Dynamic)
      {
         Sys.println("Could not copy " + inFrom + " to " + inTo + ":" + e);
         Sys.exit(1);
      }
   }

   public static function copyRecursive(inFrom:String, inTo:String)
   {
      if (!FileSystem.exists(inFrom))
      {
         Sys.println("Invalid copy : " + inFrom);
         Sys.exit(1);
      }
      if (FileSystem.isDirectory(inFrom))
      {
         mkdir(inTo);
         for(file in FileSystem.readDirectory(inFrom))
         {
            if (file.substr(0,1)!=".")
               copyRecursive(inFrom + "/" + file, inTo + "/" + file);
         }

      }
      else
         copy(inFrom,inTo);
   }


   public static function runIn(inDir:String, inExe:String, inArgs:Array<String>)
   {
      var oldPath:String = Sys.getCwd();
      Sys.setCwd(inDir);
      var result = Sys.command(inExe,inArgs);
      if (result != 0)
      {
         Sys.exit(result);
      }
      Sys.setCwd(oldPath);
   }

   public function buildSsl(inVer:String)
   {
      var links = [
          {name:"aes.h", src:"crypto/aes/aes.h"},
          {name:"asn1.h", src:"crypto/asn1/asn1.h"},
          {name:"asn1_mac.h", src:"crypto/asn1/asn1_mac.h"},
          {name:"asn1t.h", src:"crypto/asn1/asn1t.h"},
          {name:"bio.h", src:"crypto/bio/bio.h"},
          {name:"blowfish.h", src:"crypto/bf/blowfish.h"},
          {name:"bn.h", src:"crypto/bn/bn.h"},
          {name:"buffer.h", src:"crypto/buffer/buffer.h"},
          {name:"camellia.h", src:"crypto/camellia/camellia.h"},
          {name:"cast.h", src:"crypto/cast/cast.h"},
          {name:"cmac.h", src:"crypto/cmac/cmac.h"},
          {name:"cms.h", src:"crypto/cms/cms.h"},
          {name:"comp.h", src:"crypto/comp/comp.h"},
          {name:"conf.h", src:"crypto/conf/conf.h"},
          {name:"conf_api.h", src:"crypto/conf/conf_api.h"},
          {name:"crypto.h", src:"crypto/crypto.h"},
          {name:"des.h", src:"crypto/des/des.h"},
          {name:"des_old.h", src:"crypto/des/des_old.h"},
          {name:"dh.h", src:"crypto/dh/dh.h"},
          {name:"dsa.h", src:"crypto/dsa/dsa.h"},
          {name:"dso.h", src:"crypto/dso/dso.h"},
          {name:"dtls1.h", src:"ssl/dtls1.h"},
          {name:"e_os2.h", src:"e_os2.h"},
          {name:"ebcdic.h", src:"crypto/ebcdic.h"},
          {name:"ec.h", src:"crypto/ec/ec.h"},
          {name:"ecdh.h", src:"crypto/ecdh/ecdh.h"},
          {name:"ecdsa.h", src:"crypto/ecdsa/ecdsa.h"},
          {name:"engine.h", src:"crypto/engine/engine.h"},
          {name:"err.h", src:"crypto/err/err.h"},
          {name:"evp.h", src:"crypto/evp/evp.h"},
          {name:"hmac.h", src:"crypto/hmac/hmac.h"},
          {name:"idea.h", src:"crypto/idea/idea.h"},
          {name:"krb5_asn.h", src:"crypto/krb5/krb5_asn.h"},
          {name:"kssl.h", src:"ssl/kssl.h"},
          {name:"lhash.h", src:"crypto/lhash/lhash.h"},
          {name:"md4.h", src:"crypto/md4/md4.h"},
          {name:"md5.h", src:"crypto/md5/md5.h"},
          {name:"mdc2.h", src:"crypto/mdc2/mdc2.h"},
          {name:"modes.h", src:"crypto/modes/modes.h"},
          {name:"obj_mac.h", src:"crypto/objects/obj_mac.h"},
          {name:"objects.h", src:"crypto/objects/objects.h"},
          {name:"ocsp.h", src:"crypto/ocsp/ocsp.h"},
          {name:"opensslconf.h", src:"crypto/opensslconf.h"},
          {name:"opensslv.h", src:"crypto/opensslv.h"},
          {name:"ossl_typ.h", src:"crypto/ossl_typ.h"},
          {name:"pem.h", src:"crypto/pem/pem.h"},
          {name:"pem2.h", src:"crypto/pem/pem2.h"},
          {name:"pkcs12.h", src:"crypto/pkcs12/pkcs12.h"},
          {name:"pkcs7.h", src:"crypto/pkcs7/pkcs7.h"},
          {name:"pqueue.h", src:"crypto/pqueue/pqueue.h"},
          {name:"rand.h", src:"crypto/rand/rand.h"},
          {name:"rc2.h", src:"crypto/rc2/rc2.h"},
          {name:"rc4.h", src:"crypto/rc4/rc4.h"},
          {name:"ripemd.h", src:"crypto/ripemd/ripemd.h"},
          {name:"rsa.h", src:"crypto/rsa/rsa.h"},
          {name:"safestack.h", src:"crypto/stack/safestack.h"},
          {name:"seed.h", src:"crypto/seed/seed.h"},
          {name:"sha.h", src:"crypto/sha/sha.h"},
          {name:"srp.h", src:"crypto/srp/srp.h"},
          {name:"srtp.h", src:"ssl/srtp.h"},
          {name:"ssl.h", src:"ssl/ssl.h"},
          {name:"ssl2.h", src:"ssl/ssl2.h"},
          {name:"ssl23.h", src:"ssl/ssl23.h"},
          {name:"ssl3.h", src:"ssl/ssl3.h"},
          {name:"stack.h", src:"crypto/stack/stack.h"},
          {name:"symhacks.h", src:"crypto/symhacks.h"},
          {name:"tls1.h", src:"ssl/tls1.h"},
          {name:"ts.h", src:"crypto/ts/ts.h"},
          {name:"txt_db.h", src:"crypto/txt_db/txt_db.h"},
          {name:"ui.h", src:"crypto/ui/ui.h"},
          {name:"ui_compat.h", src:"crypto/ui/ui_compat.h"},
          {name:"whrlpool.h", src:"crypto/whrlpool/whrlpool.h"},
          {name:"x509.h", src:"crypto/x509/x509.h"},
          {name:"x509_vfy.h", src:"crypto/x509/x509_vfy.h"},
          {name:"x509v3.h", src:"crypto/x509v3/x509v3.h"},
          {name:"o_dir.h", src:"crypto/o_dir.h"},
          {name:"e_os.h", src:"e_os.h"},
          {name:"e_os2.h", src:"e_os2.h"},
          ];

      var dir = 'unpack/openssl-$inVer';
      untar(dir,"openssl-" + inVer + ".tar.gz");
      mkdir("include/openssl");
      for(link in links)
         copy(dir + "/" + link.src, "include/openssl/" + link.name);

      copy("buildfiles/openssl.xml", dir);
      runIn(dir, "haxelib", ["run", "hxcpp", "openssl.xml" ].concat(buildArgs));
   }

   public static function main()
   {
      new Build( Sys.args() );
   }
}


