% offline process

clear all
clc
filename='dibao\jingzhi75dB';
% �˴� n.wav ��������VAD���ж�
[n fs]=wavread([filename '_N.wav']);
% ��ͨ�������ļ�
filein=[filename '.wav'];
% processed output
out=zeros(length(n),1);

nfft=256; % half overlap
nbin=nfft/2+1; 
beta=5;
% ���߷�ʽ������������VAD����������ǰ��������μ������Rnn
% �ж������Σ�ȡ����������
start=1;
ending=0;
flag=0; % ��ʶ������
nflag=0; %��ʶ�����ν�β
while (ending<length(n)-nfft)
    ending=ending+nfft; % one frame
    
    ntmp=n(ending-nfft+1:ending);
    npower=sum(ntmp.^2);
    if npower==0 && nflag==0    %��������Ϊ0�����������������ο�ʼ
        flag=1;     
        nflag=1;
        % ��¼�����γ��ȣ����̫�̼���Rnnʱ����ƽ����һ�εĽ��
        nblock=wavread(filein, [start ending-nfft]);
    end
    if flag==1 && npower>0  %�����ν���������֡���֣�ȡ���öν��д���
        flag=0;
        nflag=0;
        yblock=wavread(filein, [start ending-nfft]);
        if ending>0
            % processing
            Nblock=stft_multi_2(nblock, nfft);
            Yblock=stft_multi_2(yblock, nfft);
            % calc average Rnn Ryy
            Rnn=average_psd(Nblock);
            if size(Nblock,1)<10
                Rnn=0.9*Rnn_old+0.1*Rnn;
            end
            Rnn_old=Rnn;
            Ryy=average_psd(Yblock);
            % PMWF
            Y_pmwf=process_pmwf_0620(Rnn, Ryy, Yblock, beta);
            %
            out(start:ending-nfft)=istft_multi_2(Y_pmwf, size(yblock,1));
            
%             out(start:ending-nfft)=out(start:ending-nfft)/max(out(start:ending-nfft));
            % end process
        end
        start=ending-nfft+1;
    end
end

% output
wavwrite(out,fs,[filename '_p' int2str(beta) '.wav']);



