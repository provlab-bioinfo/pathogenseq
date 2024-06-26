include { 
    MINIMAP2_ALIGN as MINIMAP2_ALIGN_DEPTH_ILLUMINA
} from '../../modules/local/minimap2/align/main'
include { 
    SAMTOOLS_SORT as SAMTOOLS_SORT_DEPTH_ILLUMINA
} from '../../modules/nf-core/samtools/sort/main'
include { 
    SAMTOOLS_INDEX as SAMTOOLS_INDEX_DEPTH_ILLUMINA 
} from '../../modules/nf-core/samtools/index/main'
include { 
    SAMTOOLS_COVERAGE as SAMTOOLS_COVERAGE_DEPTH_ILLUMINA 
} from '../../modules/nf-core/samtools/coverage/main'
include { 
    MAPPINGREPORT as MAPPINGREPORT_ILLUMINA
} from '../../modules/local/mappingreport'

workflow DEPTH_ILLUMINA {   

    take:
        illumina_reads
        contigs
    main:
        ch_versions = Channel.empty()

        illumina_reads.map{
            meta, reads ->
                def new_meta = [:]
                new_meta.id = meta.id
                [ new_meta, meta, reads ] 

        }.set{
            ch_input_reads
        }
        //ch_input_reads.view()
        contigs.map{
            meta, contigs ->
                def new_meta = [:]
                new_meta.id = meta.id
                [ new_meta, meta, contigs ] 
        }.set{
            ch_input_contigs
        }
        //ch_input_contigs.view()
        /* illumina_reads.join(contigs).multiMap{
            it ->
                reads: [it[0], it[1]]
                fasta_contigs: it[2]
        }.set{
            ch_input
        } */
        //ch_input_reads.join(ch_input_contigs, by: [0]).view()
        ch_input_reads.join(ch_input_contigs).multiMap{
            it ->
                reads: [it[1], it[2]]
                fasta_contigs: it[4]
        }.set{
            ch_input
        }

       /*  contigs.map{
            meta, contigs -> contigs
        }.set{ fasta }
        */
        bam_format = true
        cigar_paf_format = false
        cigar_bam = false

        //MINIMAP2_ALIGN_DEPTH_ILLUMINA( reads, fasta, bam_format, cigar_paf_format, cigar_bam)
        MINIMAP2_ALIGN_DEPTH_ILLUMINA( ch_input.reads, ch_input.fasta_contigs, bam_format, cigar_paf_format, cigar_bam)
        ch_versions = ch_versions.mix(MINIMAP2_ALIGN_DEPTH_ILLUMINA.out.versions.first())

        SAMTOOLS_SORT_DEPTH_ILLUMINA(MINIMAP2_ALIGN_DEPTH_ILLUMINA.out.bam)
        SAMTOOLS_INDEX_DEPTH_ILLUMINA(SAMTOOLS_SORT_DEPTH_ILLUMINA.out.bam)
        SAMTOOLS_COVERAGE_DEPTH_ILLUMINA(SAMTOOLS_SORT_DEPTH_ILLUMINA.out.bam.join(SAMTOOLS_INDEX_DEPTH_ILLUMINA.out.bai))
        ch_versions = ch_versions.mix(SAMTOOLS_COVERAGE_DEPTH_ILLUMINA.out.versions.first())
        
        MAPPINGREPORT_ILLUMINA(SAMTOOLS_COVERAGE_DEPTH_ILLUMINA.out.coverage)

    emit:
        contig_coverage = SAMTOOLS_COVERAGE_DEPTH_ILLUMINA.out.coverage
        sample_coverage = MAPPINGREPORT_ILLUMINA.out.tsv
        versions = ch_versions
       

}
