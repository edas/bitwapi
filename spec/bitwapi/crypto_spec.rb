# Most of the tests here originated from the the file /spec/cipherstring_spec.rb
# in the 'bitwarden-ruby' project, and was modified since then.
#
# The original code is Copyright (c) 2017 joshua stein <jcs@jcs.org> 
# and licensed under the ISC license
#
# https://github.com/jcs/bitwarden-ruby/blob/master/LICENSE
# https://github.com/jcs/bitwarden-ruby/blob/ba61496b1cc10671ce51c93415026438af0d259f/spec/cipherstring_spec.rb

require 'base64'

RSpec.describe Bitwapi::Crypto do

  describe "#make_master_key" do

    let(:b64_key) { "2K4YP5Om9r5NpA7FCS4vQX5t+IC4hKYdTJN/C20cz9c=" }

    context "when email: 'nobody@example.com' and password: 'this is a password'" do
      let(:email) { 'nobody@example.com' }
      let(:password) { 'this is a password' }
      it { expect(Base64.strict_encode64(subject.make_master_key(password, email))).to eq(b64_key) }

      context "when a case change in email" do
        let(:changed_email) { 'NOBODY@example.com' }
        it "should not change the result" do
          previous_result = subject.make_master_key(password, email)
          expect(subject.make_master_key(password, changed_email)).to eq(previous_result)
        end
      end

      context "when a change in password" do
        let(:changed_password) { 'this IS a password' }
        it "should change the result" do
          previous_result = subject.make_master_key(password, email)
          expect(subject.make_master_key(changed_password, email)).not_to eq(previous_result)
        end
      end
    end

  end

  describe "#make_key" do

    let(:b64_key) { "2K4YP5Om9r5NpA7FCS4vQX5t+IC4hKYdTJN/C20cz9c=" }

    context "when salt: 'nobody@example.com' and password: 'this is a password'" do
      let(:salt) { 'nobody@example.com' }
      let(:password) { 'this is a password' }
      it { expect(Base64.strict_encode64(subject.make_key(password, salt))).to eq(b64_key) }

      context "when a change in salt" do
        let(:changed_salt) { 'NOBODY@example.com' }
        it "should change the result" do
          previous_result = subject.make_key(password, salt)
          expect(subject.make_key(password, changed_salt)).not_to eq(previous_result)
        end
      end

      context "when a change in password" do
        let(:changed_password) { 'this IS a password' }
        it "should change the result" do
          previous_result = subject.make_key(password, salt)
          expect(subject.make_key(changed_password, salt)).not_to eq(previous_result)
        end
      end
    end
  end

  describe "#hash_password" do

    let(:b64_key) { "VRlYxg0x41v40mvDNHljqpHcqlIFwQSzegeq+POW1ww=" }

    context "when salt: 'user@example.com' and password: 'secret password'" do
      let(:salt) { 'user@example.com' }
      let(:password) { 'secret password' }
      it { expect(subject.hash_password(password, salt)).to eq(b64_key) }

      context "when a change in salt" do
        let(:changed_salt) { 'NOBODY@example.com' }
        it "should change the result" do
          previous_result = subject.hash_password(password, salt)
          expect(subject.hash_password(password, changed_salt)).not_to eq(previous_result)
        end
      end

      context "when a change in password" do
        let(:changed_password) { 'this IS a password' }
        it "should change the result" do
          previous_result = subject.hash_password(password, salt)
          expect(subject.hash_password(changed_password, salt)).not_to eq(previous_result)
        end
      end
    end

  end

  describe "#make_enc_key" do
    let(:internal_key) { subject.make_key('this is a password', 'nobody@example.com') }
    context "when with internal key derived from #make_key" do
      it "should be a decodable_cipher_string" do
        enc_key = subject.make_enc_key(internal_key)
        expect( subject.decompose_cipher_string(enc_key) ).to be_a(Array)
      end

      it "should be an AES-256-CBC cipher string" do
        enc_key = subject.make_enc_key(internal_key)
        type, iv, ct, mac = subject.decompose_cipher_string(enc_key)
        expect( type ).to eq(0)
      end

      it "should not have a mac component" do
        enc_key = subject.make_enc_key(internal_key)
        type, iv, ct, mac = subject.decompose_cipher_string(enc_key)
        expect( mac ).to be_nil
      end

      it "should be different each time" do
        expect(subject.make_enc_key(internal_key)).not_to eq(subject.make_enc_key(internal_key))
      end
    end
  end

  describe "#decrypted_key" do
    let(:email) { "this.is.me@example.com" }
    let(:password) { "this is not a good password" }
    let(:master_key) { Base64.decode64("Lqqg1CvuUp6Lq7LuU3ktpus8FXMSvloTXHnFNLlI8OI=") }
    let(:encrypted_key) { "0.Ah1dfJ//WjegyKBNl4Ix+A==|CHOvDWcsrHSIHuUj8hcCZpvB5+54BKf4eZbjpyo89p/Ziqcgzmrg2Js4mH9uYlzIZZk0Byc8DhAqJqRFPBfFADFGqZmAcKoFoj3++wav3B0=" }
    let(:decrypted_key) { Base64.decode64("jahq8PuXjiqJ3v6v//kSVaAwt/hCkhcjifiKVQWaraHz95N2I7Q0mNKbt1mStRvxhPmJGF24ENI020i2FBFuoA==")}
    
    context "when a new key from 'this.is.me@example.com' and 'this is not a good password'" do
      it "should be able to recover a decrypted key" do
        expect{ subject.decrypted_key(encrypted_key, email, password) }.not_to raise_error
      end
      it "should be of 64 bytes length" do
        expect( subject.decrypted_key(encrypted_key, email, password) ).to satisfy {|s| s.bytes.length == 64 }
      end
      it { expect( subject.decrypted_key(encrypted_key, email, password) ).to eq(decrypted_key) }
    end
  end

  describe "#split_key" do
    context "when with a 64 bytes key + mac" do
      let(:combined) { Base64.decode64("jahq8PuXjiqJ3v6v//kSVaAwt/hCkhcjifiKVQWaraHz95N2I7Q0mNKbt1mStRvxhPmJGF24ENI020i2FBFuoA==") }
      let(:key) { Base64.decode64("jahq8PuXjiqJ3v6v//kSVaAwt/hCkhcjifiKVQWaraE=") }
      let(:mac) { Base64.decode64("8/eTdiO0NJjSm7dZkrUb8YT5iRhduBDSNNtIthQRbqA=") }
      it "should return two component" do
        expect( subject.split_key(combined) ).to satisfy {|s| s.size == 2 }
      end
      it "should return a 32B key" do
        expect( subject.split_key(combined)[0] ).to satisfy {|s| s.bytes.length == 32 }
      end
      it "should return a 32B mac" do
        expect( subject.split_key(combined)[1] ).to satisfy {|s| s.bytes.length == 32 }
      end
      it "should return the expected key" do
        expect( subject.split_key(combined)[0] ).to eq(key)
      end
      it "should return the expected mac" do
        expect( subject.split_key(combined)[1] ).to eq(mac)
      end
    end
  end


  describe "#compose_cipher_string" do

    context "with a cipherstring from #make_key" do
      let(:cipherstring) { "0.u7ZhBVHP33j7cud6ImWFcw==|WGcrq5rTEMeyYkWywLmxxxSgHTLBOWThuWRD/6gVKj77+Vd09DiZ83oshVS9+gxyJbQmzXWilZnZRD/52tah1X0MWDRTdI5bTnTf8KfvRCQ=" }
      let(:type) { 0 }
      let(:iv) { Base64.decode64("u7ZhBVHP33j7cud6ImWFcw==") }
      let(:ct) { Base64.decode64("WGcrq5rTEMeyYkWywLmxxxSgHTLBOWThuWRD/6gVKj77+Vd09DiZ83oshVS9+gxyJbQmzXWilZnZRD/52tah1X0MWDRTdI5bTnTf8KfvRCQ=") }
      it { expect(subject.compose_cipher_string(type, iv, ct)).to eq(cipherstring) }
    end

    context "with a cipherstring with a mac" do 
      let(:cipherstring) { "2.ftF0nH3fGtuqVckLZuHGjg==|u0VRhH24uUlVlTZd/uD1lA==|XhBhBGe7or/bXzJRFWLUkFYqauUgxksCrRzNmJyigfw=" }
      let(:type) { 2 }
      let(:iv) { Base64.decode64("ftF0nH3fGtuqVckLZuHGjg==") }
      let(:ct) { Base64.decode64("u0VRhH24uUlVlTZd/uD1lA==") }
      let(:mac) { Base64.decode64("XhBhBGe7or/bXzJRFWLUkFYqauUgxksCrRzNmJyigfw=") }
      it { expect(subject.compose_cipher_string(type, iv, ct, mac)).to eq(cipherstring) }
    end

  end


  describe "#decrypt" do
    context "when with 'E3D5.fr' encrypted with a static key" do
      let(:encrypted) { "2.jFGpY/YtEwK1MLc0DXwTWw==|cjbabmB8oJif9ZsrIiWfvw==|XfhQe6eE2zPNxPPNe9/45s+RiqkfFYNg+d6Lp2D0BLk=" }
      let(:key) { Base64.decode64 "ACGSHP3xOJO7tPjrFDgL9OjFyPExDg7YJbIaHFoAvgW/nstRUKC9j70ef5aIrdl2rK+TFkNLc2uu0kdzBlSpCw==" }
      let(:decrypted) { "E3D5.fr" }
      it { expect( subject.decrypt(encrypted, key) ).to eq(decrypted) }
    end
  end

  describe "#encrypt" do
    context "when provided the text 'E3D5.fr' with a static key" do
      let(:key) { Base64.decode64 "ACGSHP3xOJO7tPjrFDgL9OjFyPExDg7YJbIaHFoAvgW/nstRUKC9j70ef5aIrdl2rK+TFkNLc2uu0kdzBlSpCw==" }
      let(:decrypted) { "E3D5.fr" }
      it "should return a cipher string" do
        encrypted = subject.encrypt(decrypted, key)
        expect( subject.decompose_cipher_string(encrypted)[3] ).to be_truthy
      end
      it "should be decryptable to the original text" do
        encrypted = subject.encrypt(decrypted, key)
        expect( subject.decrypt(encrypted, key) ).to eq(decrypted)
      end
    end
  end

  describe "full journey" do
    context "when email is 'nobody@example.com' and password is 'e3d5.fr'" do
      let(:email) { 'nobody@example.com'}
      let(:password) { 'bitwapi API' }
      let(:text) { 'https://e3d5.fr/'}
      it "create a key, encrypt, decrypt" do
        master_hash = subject.hash_password(password, email)
        master_key = subject.make_master_key(password, email)
        encrypted_key = subject.make_enc_key(master_key)
        decrypted_key = subject.decrypted_key(encrypted_key, email, password)
        encrypted_text = subject.encrypt(text, decrypted_key)
        decrypted_text = subject.decrypt(encrypted_text, decrypted_key)
        expect(decrypted_text).to eq(text)
      end
    end
  end


  describe "#decompose_cipher_string" do

    context "with a cipherstring from #make_key" do
      let(:cipherstring) { "0.u7ZhBVHP33j7cud6ImWFcw==|WGcrq5rTEMeyYkWywLmxxxSgHTLBOWThuWRD/6gVKj77+Vd09DiZ83oshVS9+gxyJbQmzXWilZnZRD/52tah1X0MWDRTdI5bTnTf8KfvRCQ=" }
      let(:type) { 0 }
      let(:iv) { "u7ZhBVHP33j7cud6ImWFcw==" }
      let(:ct) { "WGcrq5rTEMeyYkWywLmxxxSgHTLBOWThuWRD/6gVKj77+Vd09DiZ83oshVS9+gxyJbQmzXWilZnZRD/52tah1X0MWDRTdI5bTnTf8KfvRCQ=" }
      it "should return type, iv and ct" do
        _type, _iv, _ct = subject.decompose_cipher_string(cipherstring)
        expect(_type).to eq(type)
        expect(_iv).to eq(Base64.decode64(iv))
        expect(_ct).to eq(Base64.decode64(ct))
      end
    end

    context "with a cipherstring with a mac" do 
      let(:cipherstring) { "2.ftF0nH3fGtuqVckLZuHGjg==|u0VRhH24uUlVlTZd/uD1lA==|XhBhBGe7or/bXzJRFWLUkFYqauUgxksCrRzNmJyigfw=" }
      let(:type) { 2 }
      let(:iv) { "ftF0nH3fGtuqVckLZuHGjg==" }
      let(:ct) { "u0VRhH24uUlVlTZd/uD1lA==" }
      let(:mac) { "XhBhBGe7or/bXzJRFWLUkFYqauUgxksCrRzNmJyigfw=" }
      it "should return type, iv and ct" do
        _type, _iv, _ct, _mac = subject.decompose_cipher_string(cipherstring)
        expect(_type).to eq(type)
        expect(_iv).to eq(Base64.decode64(iv))
        expect(_ct).to eq(Base64.decode64(ct))
        expect(_mac).to eq(Base64.decode64(mac))
      end
    end

  end

end