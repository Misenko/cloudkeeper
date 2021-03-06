describe Cloudkeeper::Entities::Convertables::Convertable do
  subject(:convertable_instance_raw) do
    Class.new do
      attr_accessor :file, :format, :checksum
      include Cloudkeeper::Entities::Convertables::Convertable
    end.new
  end

  let(:convertable_instance_qcow2) do
    Class.new do
      attr_accessor :file, :format, :checksum
      include Cloudkeeper::Entities::Convertables::Convertable
    end.new
  end

  before do
    convertable_instance_raw.file = File.join(MOCK_DIR, 'image_conversions', 'image.raw')
    convertable_instance_raw.format = :raw
    convertable_instance_raw.checksum = '0d8ce85be8cce1bba62db93e01c882f4ffb5a13141e255919e5048c7f7ad08bb204bd5d176c78dbada068476fc' \
                                        'f5da8ee4963feee14e20fe82bc8efb14d7211f'

    convertable_instance_qcow2.file = File.join(MOCK_DIR, 'image_conversions', 'image.qcow2')
    convertable_instance_qcow2.format = :qcow2
    convertable_instance_qcow2.checksum = '1f9f7ea530ac8200f7b29e6544b9933487361957b8272c4a30219b2639e1d2aa2731c3a792cfe042fd494590' \
                                          '9ed510f4882a28293ec37ac898e566c02d315b89'

    Cloudkeeper::Settings[:'qemu-img-binary'] = '/dummy/binary/qemu-img'
  end

  it "won't include into class without file and format methods" do
    expect { Class.new { include Cloudkeeper::Entities::Convertables::Convertable } }.to \
      raise_error(Cloudkeeper::Errors::Convertables::ConvertabilityError)
  end

  describe '.image_file' do
    it 'returns new instance of ImageFile' do
      image_file = convertable_instance_raw.send(:image_file, convertable_instance_raw.file, :raw)
      expect(image_file.file).to eq(convertable_instance_raw.file)
      expect(image_file.format).to eq(:raw)
      expect(image_file.checksum).to eq(convertable_instance_raw.checksum)
    end
  end

  describe '.run_convert_command' do
    before do
      allow(Cloudkeeper::CommandExecutioner).to receive(:execute).with(Cloudkeeper::Settings[:'qemu-img-binary'],
                                                                       'convert',
                                                                       '-f',
                                                                       'raw',
                                                                       '-O',
                                                                       'qcow2',
                                                                       convertable_instance_raw.file,
                                                                       convertable_instance_qcow2.file)
    end

    it 'calls qemu-img binary with specified options' do
      expect { convertable_instance_raw.send(:run_convert_command, :qcow2, convertable_instance_qcow2.file) }.not_to raise_error
    end
  end

  describe '.convert_output_formats' do
    it 'returns an array of supported output fortmats' do
      expect(convertable_instance_raw.convert_output_formats).to eq(%i[raw qcow2 vmdk vdi])
    end
  end

  describe '.convert' do
    context 'with different supported output format' do
      before do
        allow(Cloudkeeper::CommandExecutioner).to receive(:execute).with(Cloudkeeper::Settings[:'qemu-img-binary'],
                                                                         'convert',
                                                                         '-f',
                                                                         'raw',
                                                                         '-O',
                                                                         'qcow2',
                                                                         convertable_instance_raw.file,
                                                                         convertable_instance_qcow2.file)
      end

      it 'converts image to specified format and returns new instance of ImageFile' do
        image_file = convertable_instance_raw.send(:convert, :qcow2)
        expect(image_file.file).to eq(convertable_instance_qcow2.file)
        expect(image_file.format).to eq(:qcow2)
        expect(image_file.checksum).to eq(convertable_instance_qcow2.checksum)
      end
    end
  end

  describe '.method_missing' do
    context 'with known formats' do
      before do
        allow(Cloudkeeper::CommandExecutioner).to receive(:execute).with(Cloudkeeper::Settings[:'qemu-img-binary'],
                                                                         'convert',
                                                                         '-f',
                                                                         'raw',
                                                                         '-O',
                                                                         'qcow2',
                                                                         convertable_instance_raw.file,
                                                                         convertable_instance_qcow2.file)
      end

      it 'calls convert method' do
        image_file = convertable_instance_raw.to_qcow2
        expect(image_file.file).to eq(convertable_instance_qcow2.file)
        expect(image_file.format).to eq(:qcow2)
        expect(image_file.checksum).to eq(convertable_instance_qcow2.checksum)
      end
    end

    context 'with the same output format' do
      it 'returns itself' do
        expect(convertable_instance_raw.to_raw).to eq(convertable_instance_raw)
      end
    end

    context 'with unknown method' do
      it 'raises NoMethodError exception' do
        expect { convertable_instance_raw.nonexistent_method }.to raise_error(NoMethodError)
      end
    end
  end
end
